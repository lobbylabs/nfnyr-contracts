pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract NonFungibleNewYearsResolutions is ERC721Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bool mintPaused = false;
    bool verificationPaused = false;

    uint256 maxPerAccount = 3;

    string internal _baseURIextended;

    constructor(address owner)
        public
        ERC721("Non-fungible New Year's Resolutions", "NFNYR")
    {
        setBaseURI("https://ipfs.io/ipfs/");
        _transferOwnership(owner);
    }

    //whitelisted recipients to transfer to
    mapping(address => bool) public whitelist;

    //this maps the tokenId to IPFS hash
    mapping(uint256 => string) public tokenIdToIpfsHash;
    //this lets you look up a token by the uri (assuming there is only one of each uri for now)
    mapping(bytes32 => uint256) public uriToTokenId;

    //mapping of accountability partners to list of tokenIds they own
    mapping(address => mapping(uint256 => uint256))
        public tokenIdsByAccountabilityPartner;
    //mapping of tokenIds to the address of the accountability partner
    mapping(uint256 => address) public tokenIdToAccountabilityPartner;
    //mapping of tokenIds to the address of the accountability partner
    mapping(address => uint256) public accountabilityPartnerBalance;

    // ids that have been verified
    mapping(uint256 => bool) public tokenIdVerificationValue;
    // ids that have been verified
    mapping(uint256 => bool) public tokenIdVerificationComplete;

    /**
     * Pause minting of new tokens
     * @dev owner only
     * @return success - true if successful
     */
    function pause() public onlyOwner returns (bool success) {
        _pause();
        return true;
    }

    /**
     * Unpause minting of new tokens
     * @dev owner only
     * @return success - true if successful
     */
    function unpause() public onlyOwner returns (bool success) {
        _unpause();
        return true;
    }

    /**
     * Pause minting of new tokens
     * @dev owner only
     * @return success - true if successful
     */
    function pauseMint() public onlyOwner returns (bool success) {
        mintPaused = true;
        return true;
    }

    /**
     * Unpause minting of new tokens
     * @dev owner only
     * @return success - true if successful
     */
    function unpauseMint() public onlyOwner returns (bool success) {
        mintPaused = false;
        return true;
    }

    /**
     * Pause verification of new challenges
     * @dev owner only
     * @return success - true if successful
     */
    function pauseVerification() public onlyOwner returns (bool success) {
        verificationPaused = true;
        return true;
    }

    /**
     * Unpause verification of new challenges
     * @dev owner only
     * @return success - true if successful
     */
    function unpauseVerification() public onlyOwner returns (bool success) {
        verificationPaused = false;
        return true;
    }

    /**
     * Set verification of a users challenge
     * @param tokenId - the tokenId of the challenge
     * @param completed - true if the challenge has been verified
     * @return success - true if successful
     */
    function setVerify(uint256 tokenId, bool completed)
        public
        returns (bool success)
    {
        require(!verificationPaused, "Verification is paused");
        require(
            tokenIdVerificationComplete[tokenId] == false,
            "Token has already been verified"
        );
        require(
            tokenIdToAccountabilityPartner[tokenId] == msg.sender,
            "Only the accountability partner can verify"
        );

        tokenIdVerificationValue[tokenId] = completed;
        return true;
    }

    /**
     * Remove the verification status from the challenge
     * @param tokenId - the tokenId of the challenge
     * @return success - true if successful
     */
    function unverify(uint256 tokenId) public returns (bool success) {
        require(!verificationPaused, "Verification is paused");
        require(
            tokenIdVerificationComplete[tokenId] == true,
            "Token has not been verified"
        );
        require(
            tokenIdToAccountabilityPartner[tokenId] == msg.sender,
            "Only the accountability partner can unverify"
        );

        tokenIdVerificationComplete[tokenId] = false;
        tokenIdVerificationValue[tokenId] = false;

        return true;
    }

    /**
     * Mint a new token
     * @param tokenURI - the uri of the challenge
     * @param partner - the address of the accountability partner
     * @return id - token id minted
     */
    function mintItem(string memory tokenURI, address partner)
        public
        payable
        returns (uint256)
    {
        require(mintPaused == false, "Minting is paused");
        require(partner != msg.sender, "Cannot be your own partner");
        require(
            balanceOf(msg.sender) < maxPerAccount,
            "You have already reached the maximum number of items per account."
        );
        require(
            msg.value == 0.06 ether,
            "You must send 0.06 ether to the contract."
        );

        bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));
        require(
            uriToTokenId[uriHash] == 0,
            "This URI has already been minted."
        );

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(msg.sender, id);
        _setTokenURI(id, tokenURI);

        uriToTokenId[uriHash] = id;

        uint256 index = accountabilityPartnerBalance[partner];
        accountabilityPartnerBalance[partner]++;
        tokenIdsByAccountabilityPartner[partner][index] = id;
        tokenIdToAccountabilityPartner[id] = partner;

        return id;
    }

    function transfer(address to, uint256 tokenId) public whenNotPaused {
        require(whitelist[to] == true, "Recipient is not whitelisted.");
        _transfer(msg.sender, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        require(whitelist[to] == true, "Recipient is not whitelisted.");
        _transfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) public whenNotPaused {
        require(whitelist[msg.sender] == true, "You are not whitelisted.");
        _burn(tokenId);
    }

    /**
     * Whitelist an address
     * @param _addr - the address to whitelist
     * @param _whitelisted - true if the address is whitelisted
     */
    function setWhitelist(address _addr, bool _whitelisted) public onlyOwner {
        whitelist[_addr] = _whitelisted;
    }

    /**
     * Withdraw the balance of the contract
     * @dev owner only
     * @param _to - the address to send the balance to
     * @param _amount - the amount to send
     * @return sent - true if successful
     * @return data - data from the call
     */
    function withdraw(address payable _to, uint256 _amount)
        external
        onlyOwner
        returns (bool sent, bytes memory data)
    {
        require(_amount < address(this).balance, "Not enough balance");
        require(_amount > 0, "Amount must be greater than 0");

        (sent, data) = _to.call{value: _amount}("");
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * Set base token URI for less storage
     * @param baseURI_ - the base URI
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    /**
     * Set the URI of a token
     * @param tokenId - the tokenId of the token
     * @param _tokenURI - the uri of the token
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        tokenIdToIpfsHash[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * Get the URI of a token
     * @param tokenId - the tokenId of the token
     * @return tokenURI - the uri of the token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = tokenIdToIpfsHash[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, return the base because this shouldn't happen
        return string(abi.encodePacked(base));
    }
}
