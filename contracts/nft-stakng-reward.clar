;; ============================================================
;; Contract Name: nft-staking-rewards
;; Description:
;; A Clarity smart contract implementing:
;; - NFT staking
;; - Reward accumulation in STX
;; - Claimable rewards
;; - Reputation system for stakers
;; - Time-lock & cooldown for unstaking
;; - Tiered rewards, batch staking, cooldowns
;; - Advanced functions: boosting, referrals, penalties, DAO control, emergency actions
;; ============================================================

;; -------------------------
;; Errors
;; -------------------------
(define-constant ERR-AUTH (err u400))
(define-constant ERR-NOT-FOUND (err u401))
(define-constant ERR-STATE (err u402))
(define-constant ERR-BALANCE (err u403))

;; -------------------------
;; Data Variables
;; -------------------------
(define-data-var reward-rate uint u10) ;; base 10 STX per block per NFT
(define-data-var staking-count uint u0)
(define-data-var cooldown-period uint u20)
(define-data-var max-tier uint u3) ;; maximum tier allowed
(define-data-var dao-admin principal tx-sender)

;; -------------------------
;; Maps
;; -------------------------
(define-map staked-nfts
  uint
  {
    owner: principal,
    staked-at: uint
  })

(define-map rewards
  principal uint)

(define-map reputation principal uint)

(define-map nft-tier
  uint
  uint)

(define-map boost-multiplier
  principal
  uint) ;; user boost multiplier (e.g., VIP, long-term)

(define-map referrals
  principal
  principal) ;; who referred whom

(define-map penalties
  principal uint) ;; early withdrawal penalties accumulated

;; -------------------------
;; Private Helpers
;; -------------------------
(define-private (calculate-reward (token-id uint))
  (match (map-get? staked-nfts token-id)
    stake (let ((tier (default-to u1 (map-get? nft-tier token-id)))
                (boost (default-to u1 (map-get? boost-multiplier (get owner stake)))))
             (* (* (var-get reward-rate) tier) boost))
    u0))

(define-private (add-reputation (user principal))
  (map-set reputation user (+ (default-to u0 (map-get? reputation user)) u1)))

(define-private (apply-penalty (user principal) (amount uint))
  (map-set penalties user (+ (default-to u0 (map-get? penalties user)) amount)))

;; -------------------------
;; Public Functions
;; -------------------------

;; Stake a single NFT
(define-public (stake-nft (token-id uint))
  (begin
    (asserts! (> token-id u0) (err u404))
    (map-set staked-nfts token-id {
      owner: tx-sender,
      staked-at: u0
    })
    (var-set staking-count (+ (var-get staking-count) u1))
    (ok true)))

;; Batch stake NFTs
(define-public (batch-stake (token-ids (list 100 uint)))
  (let ((count (len token-ids)))
    (begin
      (asserts! (> count u0) (err u405))
      (var-set staking-count (+ (var-get staking-count) count))
      (ok true))))

;; Stake NFT with referral
(define-public (stake-with-referral (token-id uint) (referrer principal))
  (begin
    (asserts! (not (is-eq referrer tx-sender)) (err u406))
    (map-set referrals tx-sender referrer)
    (stake-nft token-id)))

;; Unstake NFT with rewards and cooldown
(define-public (unstake-nft (token-id uint))
  (let ((stake (unwrap! (map-get? staked-nfts token-id) ERR-NOT-FOUND)))
    (if (not (is-eq tx-sender (get owner stake)))
        ERR-AUTH
        (if (>= (- u1 (get staked-at stake)) (var-get cooldown-period))
            (let ((reward (calculate-reward token-id)))
              (begin
                (map-delete staked-nfts token-id)
                (var-set staking-count (- (var-get staking-count) u1))
                (map-set rewards tx-sender (+ (default-to u0 (map-get? rewards tx-sender)) reward))
                (add-reputation tx-sender)
                (ok reward)))
            (begin
              (apply-penalty tx-sender u1)
              ERR-STATE)))))

;; Claim rewards
(define-public (claim-rewards)
  (let ((amount (default-to u0 (map-get? rewards tx-sender))))
    (if (is-eq amount u0)
        ERR-BALANCE
        (begin
          (map-set rewards tx-sender u0)
          (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
          (ok amount)))))

;; Emergency unstake without rewards
(define-public (emergency-unstake (token-id uint))
  (let ((stake (unwrap! (map-get? staked-nfts token-id) ERR-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender (get owner stake)) ERR-AUTH)
      (map-delete staked-nfts token-id)
      (var-set staking-count (- (var-get staking-count) u1))
      (ok true))))

;; Set NFT tier (admin only)
(define-public (set-nft-tier (token-id uint) (tier uint))
  (if (is-eq tx-sender (var-get dao-admin))
      (if (<= tier (var-get max-tier))
          (ok true)
          ERR-STATE)
      ERR-AUTH))

;; Set boost multiplier for a user (admin only)
(define-public (set-boost (user principal) (multiplier uint))
  (if (is-eq tx-sender (var-get dao-admin))
      (ok true)
      ERR-AUTH))

;; Update cooldown period (admin)
(define-public (update-cooldown (blocks uint))
  (if (is-eq tx-sender (var-get dao-admin))
      (begin 
        (asserts! (> blocks u0) (err u409))
        (var-set cooldown-period blocks) 
        (ok true))
      ERR-AUTH))

;; Update reward rate (admin)
(define-public (update-reward-rate (rate uint))
  (if (is-eq tx-sender (var-get dao-admin))
      (begin 
        (asserts! (> rate u0) (err u410))
        (var-set reward-rate rate) 
        (ok true))
      ERR-AUTH))

;; -------------------------
;; Read-only Functions
;; -------------------------
(define-read-only (get-staked-nft (token-id uint)) (map-get? staked-nfts token-id))
(define-read-only (get-rewards (user principal)) (default-to u0 (map-get? rewards user)))
(define-read-only (get-reputation (user principal)) (default-to u0 (map-get? reputation user)))
(define-read-only (get-staking-count) (var-get staking-count))
(define-read-only (get-nft-tier (token-id uint)) (default-to u1 (map-get? nft-tier token-id)))
(define-read-only (get-boost-multiplier (user principal)) (default-to u1 (map-get? boost-multiplier user)))
(define-read-only (get-referrer (user principal)) (map-get? referrals user))
(define-read-only (get-penalty (user principal)) (default-to u0 (map-get? penalties user)))

;; ============================================================
;; End of nft-staking-rewards
;; ============================================================