// Copyright (C) 2017 DappHub, LLC

pragma solidity ^0.4.11;

import "ds-token/token.sol";
import "ds-exec/exec.sol";
import "ds-auth/auth.sol";
import "ds-note/note.sol";
import "ds-math/math.sol";

contract AVTSale is DSMath, DSNote, DSExec {

    DSToken public avt;

    // AVT PRICES (ETH/AVT)
    uint public constant PRIVATE_SALE_PRICE = 110;

    uint public constant PUBLIC_SALE_PRICE = 92;

    uint128 public constant CROWDSALE_SUPPLY = 10000000 ether;
    uint public constant LIQUID_TOKENS = 1500000 ether;
    uint public constant ILLIQUID_TOKENS = 2500000 ether;

    // PURCHASE LIMITS
    uint public constant CLOSED_SALE_LIMIT = 3000000 ether;
    uint public constant PUBLIC_SALE_LIMIT = 6000000 ether;

    uint public privateStart;
    uint public publicStart;

    uint public publicEnd;

    address public aventus;
    address public privateBuyer;

    uint sold;


    function AVTSale(uint privateStart_, uint publicStart_, address aventus_, address privateBuyer_) {

        avt = new DSToken("AVT");
        
        aventus = aventus_;
        privateBuyer = privateBuyer_;
        
        privateStart = privateStart_;
        publicStart = publicStart_;
        publicEnd = privateStart + 7 days;

        assert(publicStart > privateStart);

        avt.mint(CROWDSALE_SUPPLY);
        avt.setOwner(aventus);
        avt.transfer(aventus, LIQUID_TOKENS);
    }

    // overrideable for easy testing
    function time() constant returns (uint) {
        return now;
    }

    function() payable note {
        assert(time() >= privateStart && time() < publicEnd);

        bool hasPublicStarted = time() >= publicStart;
        
        uint rate = hasPublicStarted ? PUBLIC_SALE_PRICE : PRIVATE_SALE_PRICE;
        uint limit = hasPublicStarted ? PUBLIC_SALE_LIMIT : CLOSED_SALE_LIMIT;

        uint prize = mul(msg.value, rate);

        // if pre-sale period, enforce privateBuyer
        assert(hasPublicStarted || msg.sender == privateBuyer);

        assert(add(sold, prize) <= limit);

        sold = add(sold, prize);

        avt.transfer(msg.sender, prize);
        exec(aventus, msg.value); // send the ETH to multisig
    }

    function claim() {
        assert(time() >= publicStart + 1 years);
        avt.transfer(aventus, ILLIQUID_TOKENS);
    }
}
