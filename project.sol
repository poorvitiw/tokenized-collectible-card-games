// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CardGame is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Card struct to store card attributes
    struct Card {
        string name;
        uint8 attack;
        uint8 defense;
        uint8 rarity;
        string imageURI;
        bool isForSale;
        uint256 price;
    }

    // Mapping from token ID to Card
    mapping(uint256 => Card) public cards;
    
    // Mapping to track player decks
    mapping(address => uint256[]) public playerDecks;
    
    // Events
    event CardMinted(uint256 tokenId, address owner);
    event CardListed(uint256 tokenId, uint256 price);
    event CardSold(uint256 tokenId, address from, address to, uint256 price);
    event CardUsedInBattle(uint256 tokenId, address player);

    constructor(address initialOwner) 
        ERC721("EduChain Card Game", "ECG")
        Ownable(initialOwner)
    {}

    // Function to create a new card
    function mintCard(
        string memory name,
        uint8 attack,
        uint8 defense,
        uint8 rarity,
        string memory imageURI
    ) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);

        cards[newTokenId] = Card({
            name: name,
            attack: attack,
            defense: defense,
            rarity: rarity,
            imageURI: imageURI,
            isForSale: false,
            price: 0
        });

        emit CardMinted(newTokenId, msg.sender);
        return newTokenId;
    }

    // Function to list a card for sale
    function listCardForSale(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Not the card owner");
        require(price > 0, "Price must be greater than 0");
        
        // Remove card from deck before listing
        removeCardFromDeck(tokenId);

        cards[tokenId].isForSale = true;
        cards[tokenId].price = price;

        emit CardListed(tokenId, price);
    }

    // Function to buy a card
    function buyCard(uint256 tokenId) public payable {
        Card memory card = cards[tokenId];
        require(card.isForSale, "Card is not for sale");
        require(msg.value >= card.price, "Insufficient payment");

        address seller = ownerOf(tokenId);
        
        // Transfer ownership
        _transfer(seller, msg.sender, tokenId);
        
        // Transfer payment
        payable(seller).transfer(msg.value);

        // Update card status
        cards[tokenId].isForSale = false;
        cards[tokenId].price = 0;

        emit CardSold(tokenId, seller, msg.sender, msg.value);
    }

    // Function to add card to player's deck
    function addCardToDeck(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not the card owner");
        require(!cards[tokenId].isForSale, "Card is listed for sale");
        require(playerDecks[msg.sender].length < 30, "Deck is full");
        
        playerDecks[msg.sender].push(tokenId);
    }

    // Function to remove card from deck
    function removeCardFromDeck(uint256 tokenId) public {
        uint256[] storage deck = playerDecks[msg.sender];
        for (uint i = 0; i < deck.length; i++) {
            if (deck[i] == tokenId) {
                // Replace with last element and pop
                deck[i] = deck[deck.length - 1];
                deck.pop();
                break;
            }
        }
    }

    // Function to get player's deck
    function getPlayerDeck(address player) public view returns (uint256[] memory) {
        return playerDecks[player];
    }

    // Function to get card details
    function getCard(uint256 tokenId) public view returns (Card memory) {
        return cards[tokenId];
    }

    // Battle simulation function
    function simulateBattle(uint256 cardId1, uint256 cardId2) public view returns (uint256) {
        require(!cards[cardId1].isForSale && !cards[cardId2].isForSale, "Cannot battle with cards listed for sale");
        
        Card memory card1 = cards[cardId1];
        Card memory card2 = cards[cardId2];
        
        // Simple battle mechanic based on attack and defense
        uint256 card1Power = uint256(card1.attack) + uint256(card1.defense);
        uint256 card2Power = uint256(card2.attack) + uint256(card2.defense);
        
        if (card1Power > card2Power) return cardId1;
        if (card2Power > card1Power) return cardId2;
        return 0; // Draw
    }
}