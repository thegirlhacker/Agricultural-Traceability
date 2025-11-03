// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Agricultural Traceability
 * @dev Smart contract for tracking agricultural products from farm to consumer
 */
contract AgriculturalTraceability {
    
    // Struct to store product information
    struct Product {
        uint256 productId;
        string productName;
        string origin;
        address farmer;
        uint256 harvestDate;
        uint256 quantity;
        string currentLocation;
        ProductStatus status;
        uint256 timestamp;
    }
    
    // Enum for product status
    enum ProductStatus {
        Harvested,
        InTransit,
        AtWarehouse,
        AtRetailer,
        Sold
    }
    
    // Struct for tracking product journey
    struct Journey {
        address handler;
        string location;
        ProductStatus status;
        uint256 timestamp;
        string notes;
    }
    
    // State variables
    uint256 private productCounter;
    mapping(uint256 => Product) public products;
    mapping(uint256 => Journey[]) public productJourney;
    mapping(address => bool) public authorizedHandlers;
    address public owner;
    
    // Events
    event ProductRegistered(
        uint256 indexed productId,
        string productName,
        address indexed farmer,
        uint256 harvestDate
    );
    
    event ProductStatusUpdated(
        uint256 indexed productId,
        ProductStatus newStatus,
        string location,
        address indexed handler
    );
    
    event HandlerAuthorized(address indexed handler);
    event HandlerRevoked(address indexed handler);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthorized() {
        require(
            authorizedHandlers[msg.sender] || msg.sender == owner,
            "Not authorized"
        );
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(_productId > 0 && _productId <= productCounter, "Product does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        authorizedHandlers[msg.sender] = true;
    }
    
    /**
     * @dev Register a new agricultural product
     * @param _productName Name of the product
     * @param _origin Origin/farm location
     * @param _harvestDate Date of harvest (Unix timestamp)
     * @param _quantity Quantity in appropriate units
     */
    function registerProduct(
        string memory _productName,
        string memory _origin,
        uint256 _harvestDate,
        uint256 _quantity
    ) external onlyAuthorized returns (uint256) {
        require(bytes(_productName).length > 0, "Product name required");
        require(bytes(_origin).length > 0, "Origin required");
        require(_quantity > 0, "Quantity must be greater than 0");
        
        productCounter++;
        
        products[productCounter] = Product({
            productId: productCounter,
            productName: _productName,
            origin: _origin,
            farmer: msg.sender,
            harvestDate: _harvestDate,
            quantity: _quantity,
            currentLocation: _origin,
            status: ProductStatus.Harvested,
            timestamp: block.timestamp
        });
        
        // Add initial journey entry
        productJourney[productCounter].push(Journey({
            handler: msg.sender,
            location: _origin,
            status: ProductStatus.Harvested,
            timestamp: block.timestamp,
            notes: "Product harvested and registered"
        }));
        
        emit ProductRegistered(productCounter, _productName, msg.sender, _harvestDate);
        
        return productCounter;
    }
    
    /**
     * @dev Update product status and location throughout supply chain
     * @param _productId ID of the product
     * @param _newStatus New status of the product
     * @param _location Current location
     * @param _notes Additional notes about the update
     */
    function updateProductStatus(
        uint256 _productId,
        ProductStatus _newStatus,
        string memory _location,
        string memory _notes
    ) external onlyAuthorized productExists(_productId) {
        require(bytes(_location).length > 0, "Location required");
        
        Product storage product = products[_productId];
        product.status = _newStatus;
        product.currentLocation = _location;
        product.timestamp = block.timestamp;
        
        // Add journey entry
        productJourney[_productId].push(Journey({
            handler: msg.sender,
            location: _location,
            status: _newStatus,
            timestamp: block.timestamp,
            notes: _notes
        }));
        
        emit ProductStatusUpdated(_productId, _newStatus, _location, msg.sender);
    }
    
    /**
     * @dev Get complete journey history of a product
     * @param _productId ID of the product
     * @return Array of Journey structs
     */
    function getProductJourney(uint256 _productId) 
        external 
        view 
        productExists(_productId) 
        returns (Journey[] memory) 
    {
        return productJourney[_productId];
    }
    
    /**
     * @dev Get product details
     * @param _productId ID of the product
     */
    function getProduct(uint256 _productId) 
        external 
        view 
        productExists(_productId) 
        returns (Product memory) 
    {
        return products[_productId];
    }
    
    /**
     * @dev Authorize a handler (farmer, transporter, retailer, etc.)
     * @param _handler Address to authorize
     */
    function authorizeHandler(address _handler) external onlyOwner {
        require(_handler != address(0), "Invalid address");
        require(!authorizedHandlers[_handler], "Already authorized");
        
        authorizedHandlers[_handler] = true;
        emit HandlerAuthorized(_handler);
    }
    
    /**
     * @dev Revoke handler authorization
     * @param _handler Address to revoke
     */
    function revokeHandler(address _handler) external onlyOwner {
        require(_handler != address(0), "Invalid address");
        require(_handler != owner, "Cannot revoke owner");
        require(authorizedHandlers[_handler], "Not authorized");
        
        authorizedHandlers[_handler] = false;
        emit HandlerRevoked(_handler);
    }
    
    /**
     * @dev Get total number of registered products
     */
    function getTotalProducts() external view returns (uint256) {
        return productCounter;
    }
}
