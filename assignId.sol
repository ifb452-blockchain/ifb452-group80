// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// sensor struct 
contract assignId {
    struct Sensor {
        uint sensorId;
        string location;
        bool registered;
    }

    // 
    address public owner;
    mapping(address => bool) public technicians;
    mapping(uint => Sensor) public sensors;
    uint public sensorCount;

    // events
    event TechnicianAdded(address indexed tech);
    event TechnicianRemoved(address indexed tech);
    event SensorRegistered(uint indexed sensorId, address registeredBy); // here

    // make technician owner
    constructor() {
        owner = msg.sender;
        technicians[owner] = true;
        emit TechnicianAdded(owner);
    }
    
    // add technicians to register sensor
    function addTechnican(address _tech) external {
    	require(msg.sender == owner, "Only owner can add techs");
    	technicians[_tech] = true;
    	emit TechnicianAdded(_tech);
    	}
    
    // remove technicians from registering sensors
    function removeTechnicians(address _tech) external {
    	require(msg.sender == owner, "Only owner can remove techs");
    	technicians[_tech] = false;
    	emit TechnicianRemoved(_tech);
    	}
    	
    // registering sensors 
    function registerSensor(
        uint _sensorId,
        string memory _location
    ) external {
        require(!sensors[_sensorId].registered, "Already registered!");
        require(technicians[msg.sender], "Only technicians can register");

        sensors[_sensorId] = Sensor({
            sensorId: _sensorId,
            location: _location,
            registered: true
        });
	
	// new sensor added, increase count
        sensorCount++;

        emit SensorRegistered(_sensorId, msg.sender); 
    }

    // Checks to make sure sensors are registered 
    function isSensorRegistered(uint _sensorId) external view returns (bool)
    {
        return sensors[_sensorId].registered;
    }
}
