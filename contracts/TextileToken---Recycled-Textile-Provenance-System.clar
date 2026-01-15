(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_AMOUNT (err u400))
(define-constant ERR_INSUFFICIENT_BALANCE (err u402))
(define-constant ERR_INVALID_BATCH (err u403))
(define-constant ROYALTY_PERCENTAGE u5)

(define-fungible-token eco-reward-token)
(define-non-fungible-token textile-batch uint)

(define-data-var batch-counter uint u0)
(define-data-var listing-counter uint u0)
(define-data-var supply-chain-counter uint u0)

(define-map textile-batches
  uint
  {
    origin: (string-ascii 100),
    textile-type: (string-ascii 50),
    weight-kg: uint,
    recycler: principal,
    created-at: uint,
    certified: bool,
    split: bool
  }
)

(define-map recycler-registry 
  principal 
  {
    name: (string-ascii 100),
    certified: bool,
    total-batches: uint,
    total-weight: uint
  }
)

(define-map marketplace-listings 
  uint 
  {
    batch-id: uint,
    seller: principal,
    price: uint,
    active: bool
  }
)

(define-map compliance-badges 
  principal 
  {
    manufacturer: principal,
    badge-type: (string-ascii 50),
    issued-at: uint,
    valid-until: uint
  }
)

(define-map supply-chain-stages 
  uint 
  {
    batch-id: uint,
    stage-type: (string-ascii 50),
    processor: principal,
    location: (string-ascii 100),
    completed-at: uint,
    verified: bool,
    previous-stage: (optional uint)
  }
)

(define-map final-products 
  uint 
  {
    batch-id: uint,
    product-name: (string-ascii 100),
    brand: principal,
    retail-price: uint,
    consumer-qr-code: (string-ascii 200),
    created-at: uint
  }
)

(define-read-only (get-batch-info (batch-id uint))
  (map-get? textile-batches batch-id)
)

(define-read-only (get-recycler-info (recycler principal))
  (map-get? recycler-registry recycler)
)

(define-read-only (get-listing-info (listing-id uint))
  (map-get? marketplace-listings listing-id)
)

(define-read-only (get-compliance-badge (manufacturer principal))
  (map-get? compliance-badges manufacturer)
)

(define-read-only (get-eco-token-balance (account principal))
  (ft-get-balance eco-reward-token account)
)

(define-read-only (get-batch-owner (batch-id uint))
  (nft-get-owner? textile-batch batch-id)
)

(define-read-only (get-total-batches)
  (var-get batch-counter)
)

(define-read-only (get-supply-chain-stage (stage-id uint))
  (map-get? supply-chain-stages stage-id)
)

(define-read-only (get-final-product (batch-id uint))
  (map-get? final-products batch-id)
)

(define-read-only (get-batch-supply-chain-history (batch-id uint))
  (if (is-some (map-get? supply-chain-stages u1))
    (list u1)
    (list)
  )
)

(define-public (register-recycler (name (string-ascii 100)))
  (let ((caller tx-sender))
    (asserts! (is-none (map-get? recycler-registry caller)) ERR_ALREADY_EXISTS)
    (map-set recycler-registry caller {
      name: name,
      certified: false,
      total-batches: u0,
      total-weight: u0
    })
    (ok true)
  )
)

(define-public (certify-recycler (recycler principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? recycler-registry recycler)) ERR_NOT_FOUND)
    (map-set recycler-registry recycler 
      (merge (unwrap-panic (map-get? recycler-registry recycler)) {certified: true})
    )
    (ok true)
  )
)

(define-public (create-textile-batch 
  (origin (string-ascii 100))
  (textile-type (string-ascii 50))
  (weight-kg uint)
)
  (let 
    (
      (batch-id (+ (var-get batch-counter) u1))
      (caller tx-sender)
    )
    (asserts! (is-some (map-get? recycler-registry caller)) ERR_UNAUTHORIZED)
    (asserts! (> weight-kg u0) ERR_INVALID_AMOUNT)
    
    (try! (nft-mint? textile-batch batch-id caller))
    
    (map-set textile-batches batch-id {
      origin: origin,
      textile-type: textile-type,
      weight-kg: weight-kg,
      recycler: caller,
      created-at: stacks-block-height,
      certified: false,
      split: false
    })
    
    (let ((recycler-info (unwrap-panic (map-get? recycler-registry caller))))
      (map-set recycler-registry caller 
        (merge recycler-info {
          total-batches: (+ (get total-batches recycler-info) u1),
          total-weight: (+ (get total-weight recycler-info) weight-kg)
        })
      )
    )
    
    (var-set batch-counter batch-id)
    (try! (ft-mint? eco-reward-token (* weight-kg u10) caller))
    (ok batch-id)
  )
)

(define-public (certify-batch (batch-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? textile-batches batch-id)) ERR_NOT_FOUND)
    (map-set textile-batches batch-id 
      (merge (unwrap-panic (map-get? textile-batches batch-id)) {certified: true})
    )
    (let ((batch-info (unwrap-panic (map-get? textile-batches batch-id))))
      (try! (ft-mint? eco-reward-token (* (get weight-kg batch-info) u5) (get recycler batch-info)))
    )
    (ok true)
  )
)

(define-public (list-batch-for-sale (batch-id uint) (price uint))
  (let 
    (
      (listing-id (+ (var-get listing-counter) u1))
      (caller tx-sender)
    )
    (asserts! (is-eq (some caller) (nft-get-owner? textile-batch batch-id)) ERR_UNAUTHORIZED)
    (asserts! (> price u0) ERR_INVALID_AMOUNT)
    
    (map-set marketplace-listings listing-id {
      batch-id: batch-id,
      seller: caller,
      price: price,
      active: true
    })
    
    (var-set listing-counter listing-id)
    (ok listing-id)
  )
)

(define-public (buy-batch (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? marketplace-listings listing-id) ERR_NOT_FOUND))
      (buyer tx-sender)
      (seller (get seller listing))
      (batch-id (get batch-id listing))
      (price (get price listing))
      (batch-info (unwrap! (map-get? textile-batches batch-id) ERR_NOT_FOUND))
      (original-recycler (get recycler batch-info))
      (royalty (/ (* price ROYALTY_PERCENTAGE) u100))
      (seller-amount (- price royalty))
    )
    (asserts! (get active listing) ERR_NOT_FOUND)
    (asserts! (>= (ft-get-balance eco-reward-token buyer) price) ERR_INSUFFICIENT_BALANCE)

    (try! (ft-transfer? eco-reward-token royalty buyer original-recycler))
    (try! (ft-transfer? eco-reward-token seller-amount buyer seller))
    (try! (nft-transfer? textile-batch batch-id seller buyer))

    (map-set marketplace-listings listing-id
      (merge listing {active: false})
    )

    (ok true)
  )
)

(define-public (cancel-listing (listing-id uint))
  (let 
    (
      (listing (unwrap! (map-get? marketplace-listings listing-id) ERR_NOT_FOUND))
      (caller tx-sender)
    )
    (asserts! (is-eq caller (get seller listing)) ERR_UNAUTHORIZED)
    (asserts! (get active listing) ERR_NOT_FOUND)
    
    (map-set marketplace-listings listing-id 
      (merge listing {active: false})
    )
    (ok true)
  )
)

(define-public (issue-compliance-badge 
  (manufacturer principal)
  (badge-type (string-ascii 50))
  (valid-months uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set compliance-badges manufacturer {
      manufacturer: manufacturer,
      badge-type: badge-type,
      issued-at: stacks-block-height,
      valid-until: (+ stacks-block-height (* valid-months u144))
    })
    (ok true)
  )
)

(define-public (transfer-eco-tokens (amount uint) (recipient principal))
  (ft-transfer? eco-reward-token amount tx-sender recipient)
)

(define-public (burn-eco-tokens (amount uint))
  (ft-burn? eco-reward-token amount tx-sender)
)

(define-read-only (is-badge-valid (manufacturer principal))
  (match (map-get? compliance-badges manufacturer)
    badge (< stacks-block-height (get valid-until badge))
    false
  )
)

(define-read-only (get-recycler-rating (recycler principal))
  (match (map-get? recycler-registry recycler)
    info (if (get certified info)
           (if (> (get total-batches info) u10) u5 u3)
           u1)
    u0
  )
)

(define-read-only (calculate-carbon-offset (batch-id uint))
  (match (map-get? textile-batches batch-id)
    batch (* (get weight-kg batch) u2)
    u0
  )
)

(define-public (record-supply-chain-stage 
  (batch-id uint)
  (stage-type (string-ascii 50))
  (location (string-ascii 100))
  (previous-stage (optional uint))
)
  (let 
    (
      (stage-id (+ (var-get supply-chain-counter) u1))
      (caller tx-sender)
    )
    (asserts! (is-some (map-get? textile-batches batch-id)) ERR_NOT_FOUND)
    
    (map-set supply-chain-stages stage-id {
      batch-id: batch-id,
      stage-type: stage-type,
      processor: caller,
      location: location,
      completed-at: stacks-block-height,
      verified: false,
      previous-stage: previous-stage
    })
    
    (var-set supply-chain-counter stage-id)
    (try! (ft-mint? eco-reward-token u25 caller))
    (ok stage-id)
  )
)

(define-public (verify-supply-chain-stage (stage-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? supply-chain-stages stage-id)) ERR_NOT_FOUND)
    (map-set supply-chain-stages stage-id 
      (merge (unwrap-panic (map-get? supply-chain-stages stage-id)) {verified: true})
    )
    (let ((stage-info (unwrap-panic (map-get? supply-chain-stages stage-id))))
      (try! (ft-mint? eco-reward-token u15 (get processor stage-info)))
    )
    (ok true)
  )
)

(define-public (create-final-product
  (batch-id uint)
  (product-name (string-ascii 100))
  (retail-price uint)
  (consumer-qr-code (string-ascii 200))
)
  (let ((caller tx-sender))
    (asserts! (is-some (map-get? textile-batches batch-id)) ERR_NOT_FOUND)
    (asserts! (is-none (map-get? final-products batch-id)) ERR_ALREADY_EXISTS)
    (asserts! (> retail-price u0) ERR_INVALID_AMOUNT)

    (map-set final-products batch-id {
      batch-id: batch-id,
      product-name: product-name,
      brand: caller,
      retail-price: retail-price,
      consumer-qr-code: consumer-qr-code,
      created-at: stacks-block-height
    })

    (try! (ft-mint? eco-reward-token u50 caller))
    (ok true)
  )
)

(define-constant STAKING_REWARD_RATE u1)

(define-map staking-info
  principal
  {
    amount: uint,
    staked-at: uint
  }
)

(define-read-only (get-staked-amount (account principal))
  (default-to u0 (get amount (map-get? staking-info account)))
)

(define-public (stake-eco-tokens (amount uint))
  (let ((caller tx-sender))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= (ft-get-balance eco-reward-token caller) amount) ERR_INSUFFICIENT_BALANCE)
    (try! (ft-transfer? eco-reward-token amount caller (as-contract tx-sender)))
    (map-set staking-info caller {
      amount: amount,
      staked-at: stacks-block-height
    })
    (ok true)
  )
)

(define-public (unstake-eco-tokens)
  (let
    (
      (caller tx-sender)
      (stake-info (unwrap! (map-get? staking-info caller) ERR_NOT_FOUND))
      (staked-amount (get amount stake-info))
      (staked-at (get staked-at stake-info))
      (blocks-staked (- stacks-block-height staked-at))
      (rewards (* staked-amount blocks-staked STAKING_REWARD_RATE))
    )
    (try! (as-contract (ft-transfer? eco-reward-token staked-amount tx-sender caller)))
    (try! (ft-mint? eco-reward-token rewards caller))
    (map-delete staking-info caller)
    (ok rewards)
  )
)

(define-public (split-batch (batch-id uint) (weight1 uint) (weight2 uint))
  (let
    (
      (caller tx-sender)
      (batch-info (unwrap! (map-get? textile-batches batch-id) ERR_NOT_FOUND))
      (original-weight (get weight-kg batch-info))
      (new-batch-id1 (+ (var-get batch-counter) u1))
      (new-batch-id2 (+ new-batch-id1 u1))
    )
    (asserts! (is-eq (some caller) (nft-get-owner? textile-batch batch-id)) ERR_UNAUTHORIZED)
    (asserts! (not (get split batch-info)) ERR_INVALID_BATCH)
    (asserts! (> weight1 u0) ERR_INVALID_AMOUNT)
    (asserts! (> weight2 u0) ERR_INVALID_AMOUNT)
    (asserts! (is-eq (+ weight1 weight2) original-weight) ERR_INVALID_AMOUNT)
    (try! (nft-mint? textile-batch new-batch-id1 caller))
    (map-set textile-batches new-batch-id1
      (merge batch-info {
        weight-kg: weight1,
        split: false
      })
    )
    (try! (nft-mint? textile-batch new-batch-id2 caller))
    (map-set textile-batches new-batch-id2
      (merge batch-info {
        weight-kg: weight2,
        split: false
      })
    )
    (map-set textile-batches batch-id
      (merge batch-info {
        weight-kg: u0,
        split: true
      })
    )
    (var-set batch-counter new-batch-id2)
    (ok (list new-batch-id1 new-batch-id2))
)
  )
(define-public (merge-batches (batch-ids (list 2 uint)))
  (let
    (
      (caller tx-sender)
      (first-batch-id (unwrap! (element-at batch-ids u0) ERR_INVALID_BATCH))
      (first-batch (unwrap! (map-get? textile-batches first-batch-id) ERR_NOT_FOUND))
      (second-batch-id (unwrap! (element-at batch-ids u1) ERR_INVALID_BATCH))
      (second-batch (unwrap! (map-get? textile-batches second-batch-id) ERR_NOT_FOUND))
      (total-weight (+ (get weight-kg first-batch) (get weight-kg second-batch)))
      (new-batch-id (+ (var-get batch-counter) u1))
    )
    (asserts! (is-eq (len batch-ids) u2) ERR_INVALID_AMOUNT)
    (asserts! (is-eq (some caller) (nft-get-owner? textile-batch first-batch-id)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (some caller) (nft-get-owner? textile-batch second-batch-id)) ERR_UNAUTHORIZED)
    (asserts! (not (get split first-batch)) ERR_INVALID_BATCH)
    (asserts! (not (get split second-batch)) ERR_INVALID_BATCH)
    (asserts! (is-eq (get origin first-batch) (get origin second-batch)) ERR_INVALID_BATCH)
    (asserts! (is-eq (get textile-type first-batch) (get textile-type second-batch)) ERR_INVALID_BATCH)
    (try! (nft-mint? textile-batch new-batch-id caller))
    (map-set textile-batches new-batch-id {
      origin: (get origin first-batch),
      textile-type: (get textile-type first-batch),
      weight-kg: total-weight,
      recycler: caller,
      created-at: stacks-block-height,
      certified: false,
      split: false
    })
    (try! (nft-burn? textile-batch first-batch-id caller))
    (try! (nft-burn? textile-batch second-batch-id caller))
    (var-set batch-counter new-batch-id)
    (try! (ft-mint? eco-reward-token (* total-weight u10) caller))
    (ok new-batch-id)
  )
)

(define-data-var total-donations uint u0)

(define-read-only (get-total-donations)
 (var-get total-donations)
)

(define-public (donate-eco-tokens (amount uint))
 (begin
   (asserts! (> amount u0) ERR_INVALID_AMOUNT)
   (asserts! (>= (ft-get-balance eco-reward-token tx-sender) amount) ERR_INSUFFICIENT_BALANCE)
   (try! (ft-transfer? eco-reward-token amount tx-sender (as-contract tx-sender)))
   (var-set total-donations (+ (var-get total-donations) amount))
   (ok true)
 )
)
