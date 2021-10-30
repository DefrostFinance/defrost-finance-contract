// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "./defrostHelperData.sol";
contract defrostHelper is defrostHelperData {
    constructor (address multiSignature,address origin0,address origin1) 
        proxyOwner(multiSignature,origin0,origin1){
    }
}