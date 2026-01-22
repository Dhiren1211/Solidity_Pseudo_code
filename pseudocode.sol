pragma solidity ^0.8.19;

contract AcademicIntegrityV2 {
    struct Paper {
        address author;
        string hash;
        uint256 timestamp;
        string title;
        string doi;
        bool isRetracted;
    }
    
    mapping(string => Paper) public papers;
    mapping(address => string[]) public authorPapers;
    mapping(string => bool) public retractedHashes;
    
    event PaperSubmitted(address indexed author, string hash, string title, uint256 timestamp);
    event PaperRetracted(address indexed author, string hash, uint256 timestamp);
    event PaperUpdated(address indexed author, string oldHash, string newHash);
    
    error PaperAlreadyExists(string hash);
    error PaperNotFound(string hash);
    error NotAuthor(address caller, address author);
    error PaperRetracted(string hash);
    
    // Submit paper with metadata
    function submitPaper(string memory _hash, string memory _title, string memory _doi) public {
        if (bytes(papers[_hash].hash).length != 0) {
            revert PaperAlreadyExists(_hash);
        }
        if (retractedHashes[_hash]) {
            revert PaperRetracted(_hash);
        papers[_hash] = Paper({
            author: msg.sender,
            hash: _hash,
            timestamp: block.timestamp,
            title: _title,
            doi: _doi,
            isRetracted: false
        });
        
        authorPapers[msg.sender].push(_hash);
        
        emit PaperSubmitted(msg.sender, _hash, _title, block.timestamp);
    }
    
    // Submit multiple papers at once (batch operation)
    function submitPapers(
        string[] memory _hashes, 
        string[] memory _titles, 
        string[] memory _dois
    ) public {
        require(_hashes.length == _titles.length && _hashes.length == _dois.length, "Array length mismatch");
        
        for (uint i = 0; i < _hashes.length; i++) {
            submitPaper(_hashes[i], _titles[i], _dois[i]);
        }
    }
    
    // Verify paper with comprehensive info
    function verifyPaper(string memory _hash) public view returns(
        address author,
        uint256 timestamp,
        string memory title,
        string memory doi,
        bool isRetracted,
        uint256 authorPaperCount
    ) {
        Paper memory paper = papers[_hash];
        if (bytes(paper.hash).length == 0) {
            revert PaperNotFound(_hash);
        }
        
        return (
            paper.author,
            paper.timestamp,
            paper.title,
            paper.doi,
            paper.isRetracted,
            authorPapers[paper.author].length
        );
    }
    
    // Retract a paper (only by author)
    function retractPaper(string memory _hash) public {
        Paper storage paper = papers[_hash];
        if (bytes(paper.hash).length == 0) {
            revert PaperNotFound(_hash);
        }
        if (paper.author != msg.sender) {
            revert NotAuthor(msg.sender, paper.author);
        }
        
        paper.isRetracted = true;
        retractedHashes[_hash] = true;
        
        emit PaperRetracted(msg.sender, _hash, block.timestamp);
    }
    
    // Update to new version (creates new entry, links to old)
    function updatePaper(string memory _oldHash, string memory _newHash, string memory _title) public {
        Paper storage oldPaper = papers[_oldHash];
        if (bytes(oldPaper.hash).length == 0) {
            revert PaperNotFound(_oldHash);
        }
        if (oldPaper.author != msg.sender) {
            revert NotAuthor(msg.sender, oldPaper.author);
        }
        
        submitPaper(_newHash, _title, oldPaper.doi);
        
        emit PaperUpdated(msg.sender, _oldHash, _newHash);
    }
    
    // Get all papers by an author
    function getAuthorPapers(address _author) public view returns(string[] memory) {
        return authorPapers[_author];
    }
    
    // Check if paper exists and is valid (not retracted)
    function isValidPaper(string memory _hash) public view returns(bool) {
        Paper memory paper = papers[_hash];
        return bytes(paper.hash).length != 0 && !paper.isRetracted;
    }
    
    // Get paper count for an author
    function getAuthorPaperCount(address _author) public view returns(uint256) {
        return authorPapers[_author].length;
    }
}
