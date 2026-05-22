// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interface to access assignId to ensure sensors
// are registered before recording weather obs
interface assignId_sensorRegistered {
    function isSensorRegistered(uint _sensorId) external view returns (bool);
}

contract WeatherData {
    struct WeatherRecord {
        uint sensorId;
        uint rain;
        uint wind;
        uint humidity;
        uint pressure;
        uint temp;
        uint timestamp;
        bytes32 weatherHash;
    }

    // State variables
    assignId_sensorRegistered public sensorRegistered;
    // Store weather records
    mapping(uint => WeatherRecord[]) public weatherHistory;
    // event that alerts to a new recorded weather event
    event WeatherRecorded(uint indexed sensorId, uint timestamp, bytes32 weatherHash);

    // Constructor that runs when contract gets deployed
    constructor(address _sensorRegistered) {
        // _sensorRegistered is the address from `assignId` contract
        sensorRegistered = assignId_sensorRegistered(_sensorRegistered); 
    }

    // Record weather data
    function recordWeatherData(
        uint _sensorId,
        uint _rain,
        uint _wind,
        uint _humidity,
        uint _pressure,
        uint _temp,
        bytes32 _weatherHash
      ) external { 
            require(sensorRegistered.isSensorRegistered(_sensorId), "Sensor not registered!");
    

        WeatherRecord memory newRecord = WeatherRecord({
            sensorId: _sensorId,
            rain: _rain,
            wind: _wind,
            humidity: _humidity,
            pressure: _pressure,
            temp: _temp,
            timestamp: block.timestamp,
            weatherHash: _weatherHash
        });

        // Push newly recordded data 
        weatherHistory[_sensorId].push(newRecord);
        // alert that a new recording has finished
        emit WeatherRecorded(_sensorId, block.timestamp, _weatherHash);
    }
    // Get historical weather records
    function getWeatherHistory(uint _sensorId) external view returns (WeatherRecord[] memory) {
        return weatherHistory[_sensorId];
    }

    // View function to get latest record
    function getLatestRecord(uint _sensorId) external view returns (WeatherRecord memory) {
        uint length = weatherHistory[_sensorId].length;
        // if no records
        require(length > 0, "No records found.");
        // otherwise return last element
        return weatherHistory[_sensorId][length - 1];
    }

    // Count the currently stored records
    function getRecordCount(uint _sensorId) external view returns (uint) {
        return weatherHistory[_sensorId].length;
    }
}
