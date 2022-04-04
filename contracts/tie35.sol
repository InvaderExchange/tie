// SPDX-License-Identifier: MIT
//made with love by InvaderTeam <3 :V: 34
pragma solidity ^0.8.13;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed minter, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { uint256 c = a + b; if (c < a) return (false, 0); return (true, c); }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (b > a) return (false, 0); return (true, a - b); }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (a == 0) return (true, 0); uint256 c = a * b; if (c / a != b) return (false, 0); return (true, c); }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (b == 0) return (false, 0); return (true, a / b); }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (b == 0) return (false, 0); return (true, a % b); }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { require(b <= a, "SafeMath: subtraction overflow"); return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { if (a == 0) return 0; uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow"); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "SafeMath: division by zero"); return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "SafeMath: modulo by zero"); return a % b; }
}

contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender; } 
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

//contract Role {} //instead? need to understand how exploitable it will be
contract Ownable is Context {
    address private _owner;
    
    event OwnershipRelocated(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = 0x875a40A7CB1DB3F563066E748acDf58fB6334c23;
        emit OwnershipRelocated(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier ownerRestricted { require(_owner == _msgSender()); _; }

    function renounceOwnership() external ownerRestricted {
        emit OwnershipRelocated(_owner, address(0));
        _owner = address(0);
    }

    function RelocateOwnership(address newOwner) external ownerRestricted {
        require(newOwner != address(0), "Ownable_Danger: new owner is the zero address"); 
        _owner = newOwner;
        emit OwnershipRelocated(_owner, newOwner);
    }
}  

contract Lists is Ownable {
    mapping(address => bool) private _blackList;
    function WhiteList(address user) public ownerRestricted {
        require(_blackList[user], "user not blacklisted");
        _blackList[user] = false;
    }
    function BlackList(address user) public ownerRestricted {
        require(!_blackList[user], "user already blacklisted");
        _blackList[user] = true;
    }
    function BlackListed(address user) internal view returns (bool) {
        return _blackList[user];
    }
}

contract Tie35 is IERC20, Lists {
    using SafeMath for uint256;    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    string constant private _name = "TieToken 35";
    string constant private _symbol = "TIE35";
    uint256 private  _supply = 50000 * (10 ** 6);
    uint8 constant private _decimals = 6;
    bool private _reentrant_stat = false;

    modifier noReentrancy { require(!_reentrant_stat, "ReentrancyGuard: hijack detected"); _reentrant_stat = true; _; _reentrant_stat = false; }
    
    constructor() {
        _balances[owner()] = _supply;
//        emit Transfer(address(this), owner(), _supply); //we can delete this, seemed nice for debug purposes
    }

    function name() external pure returns(string memory) { return _name; }
    function symbol() external pure returns(string memory) { return _symbol; }
    function decimals() external pure returns(uint8) { return _decimals; }
    function totalSupply() external view override returns(uint256) { return _supply.div(10 ** _decimals); }       
    function balanceOf(address wallet) external view override returns(uint256) { return _balances[wallet]; } 
//need to check if blacklisted, then return backup balance since the original is redistributed imo dunno damn this shit hard af xd
    function subSupply(uint256 amount) private { _supply = _supply.sub(amount); }
    function addSupply(uint256 amount) private { _supply = _supply.add(amount); }

    function beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        require(_balances[from] >= amount, "Insufficient funds.");
        require(from != address(0), "ERC20: approve from the zero address");
        require(!BlackListed(to), "Recipient is blacklisted");
        require(to != address(0), "ERC20: burn from the zero address");
        require(amount > 0, "Empty transactions consume gas as well you moron");
    }
    function afterTokenTransfer(address to, uint256 amount) internal virtual { 
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        //require(!_blackList[owner], "Recipient is backlisted");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private noReentrancy {
        beforeTokenTransfer(from, to, amount);
        _balances[from] -= amount;
        _balances[to] += amount;      
        emit Transfer(from, to, amount);
        afterTokenTransfer(to, amount);
    }

    function transfer(address to, uint256 amount) external override returns(bool) {
       _transfer(_msgSender(), to, amount);
       return true;
    }

    function transferFrom(address from, uint256 amount) external override returns(bool) {
        beforeTokenTransfer(from, _msgSender(), amount);
        _transfer(from, _msgSender(), amount);
        _approve(from, _msgSender(), _allowances[from][_msgSender()]-amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner) external view override returns (uint256) {
        return _allowances[owner][_msgSender()];
    }
    function all_allowance(address owner, address spender) external view ownerRestricted returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]-subValue);
        return true;
    }

    function mint(address account, uint256 amount) external ownerRestricted {       
        _balances[account] += amount;
        addSupply(amount);
        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount) external ownerRestricted {
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] -= amount; 
        subSupply(amount);
        emit Burn(account, amount);
    }
}