(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_AMOUNT (err u400))
(define-constant ERR_INSUFFICIENT_BALANCE (err u402))
(define-constant ERR_INVALID_BATCH (err u403))

(define-fungible-token eco-reward-token)
(define-non-fungible-token textile-batch uint)

(define-data-var batch-counter uint u0)
(define-data-var listing-counter uint u0)

(define-map textile-batches 
  uint 
  {
    origin: (string-ascii 100),
    textile-type: (string-ascii 50),
    weight-kg: uint,
    recycler: principal,
    created-at: uint,
    certified: bool
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
      certified: false
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
    )
    (asserts! (get active listing) ERR_NOT_FOUND)
    (asserts! (>= (ft-get-balance eco-reward-token buyer) price) ERR_INSUFFICIENT_BALANCE)
    
    (try! (ft-transfer? eco-reward-token price buyer seller))
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
