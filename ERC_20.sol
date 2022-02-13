//SPDX-License-Identifier:GPL-3.0;

pragma solidity 0.8.0;

interface ERC20Interface{

    function totalsupply() external view returns(uint);
    function balanceof(address tokenowner)external view returns(uint balance);
    function transfer(address to,uint tokens)external returns(bool success);

    function allowance(address tokenowner,address spender)external view returns(uint remaining);
    function approve(address spender,uint tokens)external returns(bool success);
    function transferfrom(address from,address to,uint tokens)external returns(bool success);

    event Transfer(address indexed from,address indexed to,uint tokens);
    event Approval(address indexed tokenowner, address indexed spender,uint tokens);


}

contract DEDSEC is ERC20Interface{
    string public name="Dedsec"; //just using this name as an example..->(DISCLAIMER xD)
    string public symbol="DSC";
    uint public decimals=0;
    uint public override totalsupply;

    address public founder;
    mapping(address=>uint)public balances;

    mapping(address=>mapping(address=>uint)) allowed;

    constructor(){
        totalsupply=100000;
        founder=msg.sender;
        balances[founder]=totalsupply;
    }

    function balanceof(address tokenowner)public view override returns(uint balance){
        return balances[tokenowner];
    }

    function transfer(address to,uint tokens)public virtual override returns(bool success){
        require(balances[msg.sender]>=tokens);

        balances[to]+=tokens;
        balances[msg.sender]-=tokens;
        emit Transfer(msg.sender,to,tokens);

        return true;
    }

    function allowance(address tokenowner,address spender)view public override returns(uint){
        return allowed[tokenowner][spender];
    }

    function approve(address spender,uint tokens)public override returns(bool success){
        require(balances[msg.sender]>=tokens);
        require(tokens>0);

        allowed[msg.sender][spender]=tokens;
        
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

    function transferfrom(address from,address to,uint tokens)public virtual override returns(bool success){
        require(allowed[from][to]>=tokens);
        require(balances[from]>=tokens);

        balances[from]-=tokens;
        balances[to]+=tokens;
        allowed[from][to]-=tokens;

        emit Transfer(from,to,tokens);

        return true;
    }

}

contract DedSecICO is DEDSEC{

        address public admin;
        address payable public deposit;
        uint tokenPrice=0.001 ether;
        uint public hardCap=300 ether;
        uint public raisedAmount;
        uint public saleStart=block.timestamp;
        uint public saleEnd=block.timestamp+604800;
        uint public tokenTradeStart=saleEnd+604800;
        uint public maxInvesetment=5 ether;
        uint public minInvestment=0.1 ether;

        enum state{beforeStart,running,afterEnd,halted}
        state public icoState;
    
        constructor(address payable _deposit){
            deposit=_deposit;
            admin=msg.sender;
            icoState=state.beforeStart;
        }

        modifier onlyadmin(){
            require(msg.sender==admin);
            _;
        }

        function halt()public onlyadmin{
            icoState=state.halted;
        }

        function resume()public onlyadmin{
            icoState=state.running;
        }

        function changeDepositAddress(address payable newDeposit)public onlyadmin{
            deposit=newDeposit;
        }

        function getCurrentState()public view returns(state){
            if(icoState==state.halted){
                return state.halted;
            }
            else if(block.timestamp<saleStart){
                return state.beforeStart;
            }
            else if(block.timestamp>=saleStart && block.timestamp<=saleEnd){
                return state.running;
            }
            else{
                return state.afterEnd;
            }
        }

        event Invest(address investor,uint value,uint tokens);
        
        function invest()payable public returns(bool){
            icoState=getCurrentState();
            require(icoState==state.running);

            require(msg.value>=minInvestment && msg.value<=maxInvesetment);
            raisedAmount+=msg.value;
            require(raisedAmount<=hardCap);

            uint tokens=msg.value/tokenPrice;

            balances[msg.sender]+=tokens;
            balances[founder]-=tokens;
            deposit.transfer(msg.value);
            
            emit Invest(msg.sender,msg.value,tokens);
            return true;
        }

        receive()payable external{
            invest();
        }

        function transfer(address to,uint tokens)public  override returns(bool success){
            require(block.timestamp>tokenTradeStart);
            DEDSEC.transfer(to,tokens);
            return true;
        }


        function transferfrom(address from,address to,uint tokens)public override returns(bool success){
            require(block.timestamp>tokenTradeStart);
            DEDSEC.transferfrom(from,to,tokens);
            return true;
        }

        function burn() public returns(bool){
            icoState=getCurrentState();
            require(icoState==state.afterEnd);
            balances[founder]=0;
            return true;
        }

    }