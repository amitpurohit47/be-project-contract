// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Govt deploys contact along with officer
// all entities will connect wallet
// user requests for login
// officer verify and adds user details
// user will add land request
// user will see open requests, currently owned lands
// if someone dies govt will add the address
// officer will see open user verification requests, new land requests, will execution requests
// officer will execute all requests one by one

contract LandContract {
    struct NewUserRequest {
        address userAddress;
        address nominee;
        string aadhar;
        bool approved;
        string note;
        bool processed;
        uint256 userIndex;
    }

    struct AddLandRequest {
        address owner;
        string land;
        bool approved;
        string note;
        uint256 userIndex;
        bool processed;
    }

    struct User {
        address userAddress;
        address nominee;
        string[] landsOwned;
        string aadhar;
        AddLandRequest[] openAddLandRequests;
        uint256 totalOpenAddLandRequests;
        NewUserRequest[] openNewUserRequests;
        uint256 totalNewUserRequests;
    }

    address public manager;
    address public landOfficer;
    mapping(address => User) public userInfo;
    mapping(string => address) public landOwner;
    mapping(address => bool) public isUserPresent;
    NewUserRequest[] public newUserRequests;
    AddLandRequest[] public addLandRequests;
    address[] public willExecutionRequests;
    event UserAlreadyPresent(address user);
    event UserNotRegistered(address user);

    constructor(address Officer) {
        manager = msg.sender;
        landOfficer = Officer;
    }

    modifier restrictedManager() {
        require(msg.sender == manager);
        _;
    }

    modifier restrictedOfficer() {
        require(msg.sender == landOfficer);
        _;
    }

    function changeLandOfficer(address officer) public restrictedManager {
        landOfficer = officer;
    }

    function getNewUserRequests()
        public
        view
        restrictedOfficer
        returns (NewUserRequest[] memory)
    {
        return newUserRequests;
    }

    function getAddLandRequests()
        public
        view
        restrictedOfficer
        returns (AddLandRequest[] memory)
    {
        return addLandRequests;
    }

    function getUserLands(address user) public view returns (string[] memory) {
        return userInfo[user].landsOwned;
    }

    function getOpenNewUserRequests(address user)
        public
        view
        returns (NewUserRequest[] memory)
    {
        return userInfo[user].openNewUserRequests;
    }

    function getOpenAddLandRequest(address user)
        public
        view
        returns (AddLandRequest[] memory)
    {
        return userInfo[user].openAddLandRequests;
    }


    function requestNewUser(string memory aadhar, address nominee) public {
        if (
            isUserPresent[msg.sender]
        ) {
            emit UserAlreadyPresent(msg.sender);
            return;
        }
        uint256 totalRequests = userInfo[msg.sender].totalNewUserRequests;
        NewUserRequest memory request = NewUserRequest({
            userAddress: msg.sender,
            aadhar: aadhar,
            nominee: nominee,
            approved: false,
            note: "",
            processed: false,
            userIndex: totalRequests
        });
        newUserRequests.push(request);
        userInfo[msg.sender].openNewUserRequests.push(request);
        userInfo[msg.sender].totalNewUserRequests++;
    }

    function verifyNewUser(
        uint256 reqInd,
        bool approved,
        string memory note
    ) public restrictedOfficer {
        newUserRequests[reqInd].approved = approved;
        newUserRequests[reqInd].note = note;
        newUserRequests[reqInd].processed = true;
        userInfo[newUserRequests[reqInd].userAddress]
            .openNewUserRequests[newUserRequests[reqInd].userIndex]
            .approved = approved;
        userInfo[newUserRequests[reqInd].userAddress]
            .openNewUserRequests[newUserRequests[reqInd].userIndex]
            .note = note;
        userInfo[newUserRequests[reqInd].userAddress]
            .openNewUserRequests[newUserRequests[reqInd].userIndex]
            .processed = true;
        if (approved) {
            User storage user = userInfo[newUserRequests[reqInd].userAddress];
            user.aadhar = newUserRequests[reqInd].aadhar;
            user.userAddress = newUserRequests[reqInd].userAddress;
            user.nominee = newUserRequests[reqInd].nominee;
            isUserPresent[newUserRequests[reqInd].userAddress] = true;
        }
    }

    function changeOwnership(string memory land, address newOwner) private {
        address curOwner = landOwner[land];
        userInfo[newOwner].landsOwned.push(land);
        uint256 index = 0;
        for (uint256 i = 0; i < userInfo[curOwner].landsOwned.length; i++) {
            if (
                keccak256(bytes(userInfo[curOwner].landsOwned[i])) ==
                keccak256(bytes(land))
            ) {
                index = i;
                break;
            }
        }
        for (
            uint256 i = index;
            i < userInfo[curOwner].landsOwned.length - 1;
            i++
        ) {
            userInfo[curOwner].landsOwned[i] = userInfo[curOwner].landsOwned[
                i + 1
            ];
        }
        userInfo[curOwner].landsOwned.pop();
        landOwner[land] = newOwner;
    }

    function addWillExecutionRequest(address executorAddress)
        public
        restrictedManager
    {
        if ( !isUserPresent[executorAddress] ) {
            emit UserNotRegistered(executorAddress);
            return;
        }
        willExecutionRequests.push(executorAddress);
    }

    function executeWill() public restrictedOfficer {
        while (willExecutionRequests.length > 0) {
            address executorAddress = willExecutionRequests[
                willExecutionRequests.length - 1
            ];
            willExecutionRequests.pop();
            User storage user = userInfo[executorAddress];
            while (user.landsOwned.length > 0) {
                string storage land = user.landsOwned[
                    user.landsOwned.length - 1
                ];
                user.landsOwned.pop();
                changeOwnership(land, user.nominee);
            }
        }
    }

    function requestNewLand(string memory land) public {
        if(
            isUserPresent[msg.sender] == false
        ) {
            emit UserNotRegistered(msg.sender);
            return;
        }
        uint256 totalRequests = userInfo[msg.sender].totalOpenAddLandRequests;
        AddLandRequest memory request = AddLandRequest({
            owner: msg.sender,
            land: land,
            approved: false,
            note: "",
            userIndex: totalRequests,
            processed: false
        });
        addLandRequests.push(request);
        userInfo[msg.sender].openAddLandRequests.push(request);
        userInfo[msg.sender].totalOpenAddLandRequests++;
    }

    function verifyAddLandRequest(
        uint256 reqInd,
        bool approved,
        string memory note
    ) public restrictedOfficer {
        require(isUserPresent[addLandRequests[reqInd].owner]);
        addLandRequests[reqInd].approved = approved;
        addLandRequests[reqInd].note = note;
        addLandRequests[reqInd].processed = true;
        userInfo[addLandRequests[reqInd].owner]
            .openAddLandRequests[addLandRequests[reqInd].userIndex]
            .approved = approved;
        userInfo[addLandRequests[reqInd].owner]
            .openAddLandRequests[addLandRequests[reqInd].userIndex]
            .note = note;
        userInfo[addLandRequests[reqInd].owner]
            .openAddLandRequests[addLandRequests[reqInd].userIndex]
            .processed = true;
        if (approved) {
            userInfo[addLandRequests[reqInd].owner].landsOwned.push(
                addLandRequests[reqInd].land
            );
            landOwner[addLandRequests[reqInd].land] = addLandRequests[
                reqInd
            ].owner;
        }
    }
}
