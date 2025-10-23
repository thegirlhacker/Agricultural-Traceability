// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice A blockchain-based agricultural traceability system
 * @Roles: Admin, Farmer, Distributor, Retailer, Customer
 */

contract AgriChain {
   

    enum Role { None, Admin, Farmer, Distributor, Retailer, Customer }

    struct User {
        string name;
        Role role;
        bool isAuthorized;
    }

    struct Product {
        uint256 id;
        string name;
        string originLocation;
        string harvestDate;
        address farmer;
        address distributor;
        address retailer;
        string transportInfo;
        string retailInfo;
        bytes32 productHash;
        bool isDistributed;
        bool isRetailed;
    }

   
    address public contractOwner;
    uint256 public productCount = 0;

    mapping(address => User) public users;
    mapping(uint256 => Product) public products;
