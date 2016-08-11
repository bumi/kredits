contract LunchTracker {
    struct Member {
        address member;
        string name;
        uint index;
        bool exists; 
    }
    struct Lunch {
        address creator;
        address recipient;
        uint256 amount;
        string description;
        string ipfsHash;
        uint votes;
        mapping (address => bool) voters;
        uint createdAt; 
        bool executed;
    }
    
    address public owner;

    mapping (address => Member) public members;
    mapping (uint => address) public memberIndexes;
    uint public membersCount;

    Lunch[] public lunches;

    event LunchCreated(uint256 id, address creator, address recipient, uint256 amount, string description);
    event Voted(uint id, address voter, string description);
    event LunchAccepted(uint id, string description);
    event LunchSpent(uint id, address recipient, uint256 amount, string description);
    
    modifier membersOnly() { if (!members[msg.sender].exists) { throw; } _ }
    modifier noEther() { if (msg.value > 0) throw; _ }

    function LunchTracker() {
        owner = msg.sender;
        _addMember(msg.sender);
    }
    
    function lunchesCount() constant noEther returns(uint) {
      return lunches.length;
    }

    function addOrUpdateMember(address _address, string _name) noEther membersOnly returns(uint) {
        _addMember(_address);
        Member m = members[_address];
        m.name = _name;
        return m.index;
    }

    function removeMember(address _address) noEther membersOnly {
      _removeMember(_address); 
    }

    function addLunch(address _recipient, uint256 _amount, string _description) noEther returns (uint lunchId) {
        lunchId = lunches.length++;
        Lunch e = lunches[lunchId];
        e.creator = msg.sender;
        e.recipient = _recipient;
        e.amount = _amount;
        e.description = _description;
        e.createdAt = now;
        if(members[msg.sender].exists) {
          e.votes++;
          e.voters[msg.sender] = true;
        }
        LunchCreated(lunchId, msg.sender, e.recipient, e.amount, e.description);
    }

    function voteForLunch(uint lunchId) membersOnly noEther {
        var e = lunches[lunchId];
        if(e.executed) { throw; }
        if(e.voters[msg.sender]) { throw; } // only vote once;
        e.votes++;
        e.voters[msg.sender] = true;
        Voted(lunchId, msg.sender, e.description);
        if(e.votes >= _votesRequired()) {
            LunchAccepted(lunchId, e.description);
        }
    }

    function spendLunch(uint lunchId) membersOnly noEther {
        var e = lunches[lunchId];
        if(e.executed) { throw; }
        if(e.votes < _votesRequired()) { throw; }
        if(e.amount > this.balance) { throw; }
        e.executed = true;
        if(e.recipient.send(e.amount)) { // danger!
            LunchSpent(lunchId, e.recipient, e.amount, e.description);
        } else { throw; }
    }

    function _votesRequired() private returns (uint) {
        return membersCount / 2;
    }
    
    function _addMember(address _address) private {
      Member m = members[_address];
      m.member = _address;
      m.exists = true;
      var index = membersCount+1;
      m.index = index;
      memberIndexes[index] = _address;
      membersCount++;
    }

    function _removeMember(address _address) private {
      Member m = members[_address];
      m.exists = false;
      delete memberIndexes[m.index];
      delete members[_address];
      membersCount--;
    }

    function kill() public noEther {
      if(msg.sender != owner) { throw; }
      suicide(owner);
    }
}


