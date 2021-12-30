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

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintItem(string memory tokenURI, address partner)
        public
        returns (uint256)
    {
        require(
            balanceOf(msg.sender) < maxPerAccount,
            "You have already reached the maximum number of items per account."
        );
        bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));

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

    function setWhitelist(address _addr, bool _whitelisted) public onlyOwner {
        whitelist[_addr] = _whitelisted;
    }

    function withdraw(address payable _to, uint256 _amount)
        external
        onlyOwner
        returns (bool sent, bytes memory data)
    {
        require(_amount < address(this).balance, "Not enough balance");
        require(_amount > 0, "Amount must be greater than 0");

        (bool sent, bytes memory data) = _to.call{value: _amount}("");
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

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
