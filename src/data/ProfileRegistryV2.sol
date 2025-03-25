// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract ProfileRegistryV2 {
    struct Profile {
        uint256 domain;
        string name;
        bytes32 pictureHash;
        bytes metadata;
    }

    mapping(address => Profile) public profiles;
    mapping(uint256 => mapping(string => address)) public names;

    error NameAlreadyTaken();

    event NameUpdated(address indexed user, uint256 domain, string name);
    event AvatarUpdated(address indexed user, bytes32 pictureHash);
    event MetadataUpdated(address indexed user, bytes metadata);

    function validateName(uint256 domain, string memory name) internal view returns (bool) {
        return names[domain][name] == address(0);
    }

    /**
     * @notice Update the profile of the sender
     * @param domain The domain of the profile
     * @param name The name of the profile
     * @param pictureHash The hash of the picture of the profile
     * @param metadata The metadata of the profile
     */
    function updateProfile(uint256 domain, string memory name, bytes32 pictureHash, bytes memory metadata) public {
        updateName(domain, name);
        updateAvatar(pictureHash);
        updateMetadata(metadata);
    }

    function updateName(uint256 domain, string memory name) public {
        address user = msg.sender;

        if (names[domain][name] == user) {
            // already set
            return;
        }

        if (!validateName(domain, name)) {
            revert NameAlreadyTaken();
        }

        Profile storage profile = profiles[user];

        names[domain][profile.name] = address(0);
        profile.domain = domain;
        profile.name = name;
        names[domain][name] = user;

        emit NameUpdated(user, domain, name);
    }

    function updateAvatar(bytes32 pictureHash) public {
        address user = msg.sender;

        profiles[user].pictureHash = pictureHash;

        emit AvatarUpdated(user, pictureHash);
    }

    function updateMetadata(bytes memory metadata) public {
        address user = msg.sender;
        Profile storage profile = profiles[user];
        profile.metadata = metadata;
        emit MetadataUpdated(user, metadata);
    }

    function getProfile(address user) public view returns (Profile memory) {
        return profiles[user];
    }
}
