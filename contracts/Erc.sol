//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint256 totalTokens;
    address public owner;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    string _name;
    string _symbol;

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() public pure returns(uint256) {
        return 18;
    }

    function totalSupply() external view returns(uint256) {
        return totalTokens;
    }

    modifier enoughTokens(address _from, uint256 _amount) {
        require(balanceOf(_from) >= _amount, "Not enough tokens...");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }


    constructor(string memory name_, string memory symbol_, uint256 initialSupply, address shop) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        mint(shop, initialSupply);
    }

    function balanceOf(address account) public view returns(uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) external enoughTokens(msg.sender, amount) {
        _beforeTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function mint(address _to, uint256 amount) public onlyOwner {
        _beforeTokenTransfer(address(0), _to, amount);
        balances[_to] += amount;
        totalTokens += amount;
        emit Transfer(address(0), _to, amount);
    }

    function burn(address _from, uint256 amount) public onlyOwner enoughTokens(_from, amount) {
        _beforeTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }

    function allowance(address _owner, address spender) public view returns(uint256) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public {
        _approve(msg.sender, spender, amount);
    }

    function _approve(address sender, address spender, uint256 amount) internal virtual {
        allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external enoughTokens(sender, amount) {
        _beforeTokenTransfer(sender, recipient, amount);
        require(allowances[sender][msg.sender] >= amount, "check allowance");
        allowances[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {

    }


    fallback() external payable {

    }

    receive() external virtual payable {

    }
}


contract CryptoRandomCoffeeToken is ERC20 {
    constructor(address shop) ERC20("CryptoRandomCoffeeToken", "CRCT", 1000, shop) {}
}

contract CRCTShop {
    IERC20 public token;
    address payable public owner;
    uint256 public price = 10**15;
    event Bought(uint256 _amount, address indexed _buyer);
    event Sold(uint256 _amount, address indexed _seller);

    constructor() {
        token = new CryptoRandomCoffeeToken(address(this));
        owner = payable(msg.sender);
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    function sell(uint256 tokensToSell) external returns (bool) {
        require(tokensToSell > 0 && token.balanceOf(msg.sender) >= tokensToSell, "incorrect amount of tokens!" );

        uint256 allowance = token.allowance(msg.sender, address(this));
        require( allowance >= tokensToSell, "check allowance!");
        require (address(this).balance >= tokensToSell * price, "Not enough money");

        token.transferFrom(msg.sender, address(this), tokensToSell);
        payable(msg.sender).transfer(tokensToSell * price);
        emit Sold(tokensToSell, msg.sender);
        return true;
    }

    function buy() external payable returns (bool) {
        uint256 tokensToBuy = msg.value / price;
        require(tokensToBuy > 0, "not enough funds!");
        
        require(tokenBalance(address(this)) >= tokensToBuy, "not enough tokens!");
        token.transfer(msg.sender, tokensToBuy);
        uint256 refund = msg.value - tokensToBuy * price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        emit Bought(tokensToBuy, msg.sender);
        return true;
    }

    function tokenBalance(address user) public view returns(uint256) {
        return token.balanceOf(user);
    }

    function setPrice(uint256 newPrice) external onlyOwner returns (bool) {
        require(newPrice > 0, "New price is zero");
        price = newPrice;
        return true;
    }

    receive() external payable {}

}
