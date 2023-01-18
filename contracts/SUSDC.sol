// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DUSDC is ERC20, Ownable {
    constructor() ERC20("DUSDC", "DUSDC") {
        _mint(address(this), 100000 * 10 ** decimals());
    }

    function mintMoreToken() external onlyOwner{
        _mint(address(this), 1000 * 10 ** decimals());
    }

    function transferFromContract(address _to, uint256 amount) public onlyOwner {
        uint bal = balanceOf(address(this));
        require(bal >= amount, "You are transferring more than the amount available!");
        _transfer(address(this), _to, amount);
    }
}