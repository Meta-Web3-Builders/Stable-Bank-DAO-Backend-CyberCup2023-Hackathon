// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
interface IStableBankToken {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);


    //function transfer(address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external ;
 
    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external ;

    function burn(uint256 amount)  external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}