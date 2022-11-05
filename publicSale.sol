// SPDX-License-Identifier: MIT


pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract publicSaleApp is Ownable{
    struct infoUser{
        uint256 amount;
        // uint256 refCode;
        uint256 paymentAmount;
    }

    struct infoRefCode{
        bool isActive;
        uint256 discount;
        uint256 startTime;
        uint256 endTime;
        uint256 countTimes;
    }

    ERC20 public token;
    uint256 public totalAmount;
    mapping(address => infoUser) public listUsers;
    mapping(string  => infoRefCode) public listRefCode;
    mapping(bytes32 => bool) private checkCodeUser;

    constructor(ERC20 _token)
    {
        token = _token;
        totalAmount = 1000;
        // listRefCode[0] = infoRefCode(true,uint256(30),uint256(1667130369),uint256(1672400769),uint256(1));
        // listRefCode[1] = infoRefCode(true,uint256(20),uint256(1667130369),uint256(1672400769),uint256(2));
        // listRefCode[2] = infoRefCode(true,uint256(10),uint256(1667130369),uint256(1672400769),uint256(3));
    }

    function setRefCode(
        string[] memory _infoRefCode,
        uint256[] memory _infoDiscount,
        uint256[] memory _infoStartTime,
        uint256[] memory _infoEndTime,
        uint256[] memory _infoCountTimes
    ) public onlyOwner {
        require(_infoDiscount.length == _infoStartTime.length, "SetOptions: The inputs have the same length");
        require(_infoStartTime.length == _infoEndTime.length, "SetOptions: The inputs have the same length");
        require(_infoEndTime.length == _infoCountTimes.length, "SetOptions: The inputs have the same length");
        for(uint256 i=0; i < _infoDiscount.length; i++){
            infoRefCode memory info = infoRefCode(
                true,
                _infoDiscount[i], 
                _infoStartTime[i], 
                _infoEndTime[i], 
                _infoCountTimes[i]
            );
            listRefCode[_infoRefCode[i]] = info;
        }
    }

    function editRefCode(string memory _refCode, bool _isActive, uint256 _discount, uint256 _startTime, uint256 _endTime, uint256 _countTimes) public onlyOwner
    {
        require(listRefCode[_refCode].isActive == true, "editRefCode: The refCode is not valid");
        require(_startTime > 0, "editRefCode: The startTime is not valid");
        require(_endTime > 0, "editRefCode: The endTime is not valid");
        require(_discount > 0, "editRefCode: The discount is not valid");
        require(_startTime < _endTime, "editRefCode: The startTime is not valid");
        listRefCode[_refCode].isActive = _isActive;
        listRefCode[_refCode].discount = _discount;
        listRefCode[_refCode].startTime = _startTime;
        listRefCode[_refCode].endTime = _endTime;
        listRefCode[_refCode].countTimes = _countTimes;
    }

    function publicSale(uint256 _amount, string memory _refCode) public 
    {
        require(totalAmount > 0, "The public sale is done");
        uint256 _paidAmount;
        uint256 _userAmount;
        if(listRefCode[_refCode].isActive == true)
        {   
            bytes32 _value = keccak256(abi.encodePacked(msg.sender, _refCode));
            require(checkCodeUser[_value] == false, "The refCode is used");

            require(listRefCode[_refCode].countTimes > 0, "The refCode is not valid");
            require(listRefCode[_refCode].startTime <= block.timestamp,"The refCode is not ready to use");
            require(block.timestamp <= listRefCode[_refCode].endTime ,"The refCode is out of date");
            
            _paidAmount = (_amount * (100 - listRefCode[_refCode].discount) / 100);
            // token.transferFrom(msg.sender, address(this), paidAmount);
            checkCodeUser[_value] = true;
        }
        else
        {
            _paidAmount = _amount;
            // token.transferFrom(msg.sender, address(this), paidAmount);
        }
        _userAmount = listUsers[msg.sender].amount + _amount;
        _paidAmount = listUsers[msg.sender].paymentAmount + _paidAmount;
        infoUser memory info = infoUser(
                _userAmount, 
                _paidAmount
            );
            listUsers[msg.sender] = info;

        totalAmount = totalAmount - _amount;
        
    }

}