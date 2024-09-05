// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreelanceMarketplace {
    struct Offer {
        address payable student;
        address client;
        string studentNumber;
        string studentCardIpfsHash;
        string serviceKeyword;
        uint price;
        bool studentConfirmed;
        bool clientConfirmed;
        bool isCancelled;
        bool fundsDeposited;
    }

    struct User {
        uint score;
        uint totalReviews;
    }

    Offer[] public offers;
    mapping(address => User) public users;

    event OfferCreated(
        uint offerId,
        address indexed student,
        string serviceKeyword,
        uint price
    );
    event OfferAccepted(
        uint offerId,
        address indexed client,
        address indexed student
    );
    event OfferCompleted(
        uint offerId,
        address indexed client,
        address indexed student
    );
    event OfferCancelled(
        uint offerId,
        address indexed client,
        address indexed student
    );

    // Create a new freelance offer
    function createOffer(
        string memory _studentNumber,
        string memory _studentCardIpfsHash,
        string memory _serviceKeyword,
        uint _price
    ) public {
        require(bytes(_studentNumber).length > 0, "Student number is required");
        require(
            bytes(_studentCardIpfsHash).length > 0,
            "Student card image hash is required"
        );

        offers.push(
            Offer({
                student: payable(msg.sender),
                client: address(0),
                studentNumber: _studentNumber,
                studentCardIpfsHash: _studentCardIpfsHash,
                serviceKeyword: _serviceKeyword,
                price: _price,
                studentConfirmed: false,
                clientConfirmed: false,
                isCancelled: false,
                fundsDeposited: false
            })
        );

        uint offerId = offers.length - 1;
        emit OfferCreated(offerId, msg.sender, _serviceKeyword, _price);
    }

    // Accept an offer and deposit the funds in escrow
    function acceptOffer(uint _offerId) public payable {
        Offer storage offer = offers[_offerId];
        require(offer.client == address(0), "Offer already accepted");
        require(!offer.isCancelled, "Offer is cancelled");
        require(msg.value == offer.price, "Incorrect payment");

        // Lock the funds in the contract until completion
        offer.client = msg.sender;
        offer.fundsDeposited = true;

        emit OfferAccepted(_offerId, msg.sender, offer.student);
    }

    // Confirm completion by either the student or client
    function confirmCompletion(uint _offerId) public {
        Offer storage offer = offers[_offerId];
        require(offer.fundsDeposited, "Funds not deposited");
        require(!offer.isCancelled, "Offer is cancelled");

        if (msg.sender == offer.student) {
            offer.studentConfirmed = true;
        } else if (msg.sender == offer.client) {
            offer.clientConfirmed = true;
        } else {
            revert("Only the student or client can confirm completion");
        }

        // If both parties have confirmed, complete the offer
        if (offer.studentConfirmed && offer.clientConfirmed) {
            offer.student.transfer(offer.price); // Transfer the funds to the student
            users[offer.student].score += 3; // Award points to the student
            users[offer.client].score += 2; // Award points to the client for successful completion

            emit OfferCompleted(_offerId, offer.client, offer.student);
        }
    }

    // Cancel an offer before it is completed
    function cancelOffer(uint _offerId) public {
        Offer storage offer = offers[_offerId];
        require(
            !offer.studentConfirmed && !offer.clientConfirmed,
            "Cannot cancel after confirmation"
        );
        require(!offer.isCancelled, "Offer is already cancelled");
        require(
            msg.sender == offer.client || msg.sender == offer.student,
            "Only involved parties can cancel"
        );

        offer.isCancelled = true;

        if (offer.fundsDeposited) {
            // Refund the client if the funds were deposited
            payable(offer.client).transfer(offer.price);
        }

        // Reduce score for cancellation
        users[offer.student].score -= 1;
        users[offer.client].score -= 1;

        emit OfferCancelled(_offerId, offer.client, offer.student);
    }

    // Get the total number of offers
    function getTotalOffers() public view returns (uint) {
        return offers.length;
    }

    // Retrieve a user's score
    function getUserScore(address _user) public view returns (uint) {
        return users[_user].score;
    }
}
