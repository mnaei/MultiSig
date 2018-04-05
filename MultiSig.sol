pragma solidity ^0.4.21;

contract Plaza{
    
    /* Owner is the administrator of this wallet
    *  His authorities include:
    *      1. Propose transactions to be sent to the liquidation agent
    *      2. Propose a new liquidation agent to replace previous liquidation agent 
    *      3. return to investors their investment
    */
    address public Owner;
    
    
    /* The EscrowOfficer is the digital custodian of this wallet
    *  His authority includes:
    *      1. confirm a transactions to be sent to the liquidation agent
    *      2. confirm a new liquidation agent to replace previous liquidation agent 
    *      3. return to investors their investment
    */
    address public EscrowOfficer;
    
    
    /* The LiquidationWallet is the Ethereum wallet of the agent who will
    *  liquidate the Ether sent to them into USD
    *  
    *  Owner has the ability to propose a new LiquidationWallet address
    *  which will only replace the previous LiquidationWallet once it has
    *  been confirmed by the EscrowOfficer
    */
    address public LiquidationWallet;
    address public NewLiquidationWallet;
    

    /*
    *  Owner has the ability to propose a new transaction to be sent to
    *  liquidation agent. The amount is in Wei denominations ( 1^18 Wei = 1 Ether ).
    *  The transaction will then be confirmed by the EscrowOfficer and then be set to 0
    *
    *  Owner can cancel a proposed transaction by proposing a new transaction with 
    *  the value of 0
    */
    uint public PendingTransaction; 
    
    
    /*
    *  As each investor sends crypto currency to this wallet their address and 
    *  contribution amout will be recorded. 
    *
    *  Owner or the EscrowOfficer will be able to return to the investor their
    *  investment but only to the amount of their contributions. 
    */
    struct Investment{
        address investor;
        uint amount;
    }
    
    
    /* 
    *  As an Investment comes in it is added to the Investments list
    *  starting from 1 as the first investment and automatically incromenting
    */
    Investment[] public Investments;
    
    
    /*
    *  Sets the initial variables of the smart contract. Only called once at the 
    *  beginning of the smart contracts creation
    */
    function Plaza(address _Owner, address _EscrowOfficer, address _LiquidationWallet) public {
        Owner = _Owner;
        EscrowOfficer = _EscrowOfficer;
        LiquidationWallet = _LiquidationWallet;
        NewLiquidationWallet = _LiquidationWallet;
        PendingTransaction = 0;
    }
    
    function proposeTransaction(uint _PendingTransaction) public {
        require(msg.sender == Owner);
        PendingTransaction = _PendingTransaction;
    }
    
    function confirmTransaction(bool _accepted) public {
        require(msg.sender == EscrowOfficer);
        
        require(PendingTransaction != 0);
        if (_accepted)
            LiquidationWallet.transfer(PendingTransaction);
        PendingTransaction = 0;
    }
    
    function proposeLiquidationWallet(address _NewLiquidationWallet) public {
        require (msg.sender == Owner);
        NewLiquidationWallet = _NewLiquidationWallet;
    }
    
    function confirmLiquidationWallet(bool _accepted) public {
        require (msg.sender == EscrowOfficer);
        
        if(_accepted)
            LiquidationWallet = NewLiquidationWallet;
        else
            NewLiquidationWallet = LiquidationWallet;
    }
    
    function returnInvestment(uint _id, uint _amount) public {
        require (msg.sender == Owner || msg.sender == EscrowOfficer);
        
        require(Investments[_id].amount > _amount);
        Investments[_id].amount -= _amount;
        Investments[_id].investor.transfer(_amount);
    }
    
    function receiveInvestment() public payable {
        Investments.push(Investment({ investor: msg.sender, amount: msg.value }));
    }
    
    function() public payable{
        receiveInvestment();
    }
}
