/* Token is heavily copied from "the DAO" and from Consesys's examples*/

contract Kosmos { 

    address public creator;
    mapping (address => bool) public members;
    address[] public memberAddresses;
    Proposal[] public proposals;

    uint votesNeeded;
    struct Proposal {
        address creator;
        address recipient;
        uint votes;
        mapping (address => bool) voters;
        uint votesNeeded;
        uint256 amount;
        bool executed;
        string description;
        string ipfsHash;
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals; 

    event ProposalCreated(uint256 id, address creator, address recipient, uint256 amount, string description, string ipfsHash);
    event ProposalAccepted(uint256 id, address recipient, uint256 amount, string description, string ipfsHash);
    event ProposalExecuted(uint256 id, address recipient, uint256 amount, string description, string ipfsHash);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

    modifier membersOnly() {
        if (isMember(msg.sender) != true) { throw; }
        _
    }
    modifier noEther() {
        if (msg.value > 0) { throw; }
        _
    }
    
    function Kosmos(string _name, string _symbol) {
        name = _name; 
        symbol = _symbol;
        decimals = 0;
        votesNeeded = 1;
        creator = msg.sender;
        mintFor(msg.sender, 1);
    }

    function buy() returns (uint256) {
        if(msg.value == 0) { throw; }
        uint256 _amount = msg.value / tokenValue();
        if(_amount < 1) {
          throw;
        }
        mintFor(msg.sender, _amount);
        return _amount;
    }

    function tokenValue() constant returns (uint256) {
      uint256 value = this.balance / totalSupply;
      if(value < 1 finney) {
        return 1 finney;
      } else {
        return value;
      }
    }

    function membersCount() constant returns (uint) {
        return memberAddresses.length;
    }
    function proposalsCount() constant returns (uint) {
        return proposals.length;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) noEther returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] -= _amount;
            addMember(_to);
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
           return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) noEther returns (bool success) {

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {

            addMember(_to);
            balances[_to] += _amount;
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function addProposal(address _recipient, uint256 _amount, string _description, string _ipfsHash) public noEther membersOnly returns (uint256 proposalId) {
        proposalId = proposals.length++;
        var _votesNeeded = membersCount() / 2; // TODO: calculation depending on amount
    
        Proposal p = proposals[proposalId];
        p.creator = msg.sender;
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.ipfsHash = _ipfsHash;
        p.executed = false;
        p.votes = 0;
        p.votesNeeded = _votesNeeded;
        ProposalCreated(proposalId, msg.sender, p.recipient, p.amount, p.description, p.ipfsHash);
    }
  
    function vote(uint256 _proposalId) public noEther membersOnly returns (uint proposalId, bool executed) {
        var p = proposals[_proposalId];
        if(p.executed) { throw; }
        if(p.voters[msg.sender] == true) { throw; }

        p.votes++;
        p.voters[msg.sender] = true;
        if(p.votes >= p.votesNeeded) {
            ProposalAccepted(_proposalId, p.recipient, p.amount, p.description, p.ipfsHash);
        }
        proposalId = _proposalId;
    }

    function executeProposal(uint proposalId) noEther membersOnly public returns (bool) {
        Proposal p = proposals[proposalId];
        if(p.executed) { throw; }
        if(p.votes < p.votesNeeded) { throw; }
        if(p.amount > this.balance) { throw; }
        p.executed = true;
        if(p.recipient.send(p.amount)) { // danger!
          ProposalExecuted(proposalId, p.recipient, p.amount, p.description, p.ipfsHash);    
        } else { throw; }
    }

    function mintFor(address _address, uint _amount) private {
        addMember(_address);
        balances[_address] += _amount;
        totalSupply += _amount;
    }

    function addMember(address _address) private {
        if(members[_address] == false) { 
            members[_address] = true;
            memberAddresses.push(_address);
        }
    }

    function isMember(address _address) private returns (bool) {
        return members[_address] == true;
    }

    function kill() public noEther {
        if(msg.sender != creator) { throw; }
        suicide(creator);
    }
}


