// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ─────────────────────────────────────────────────────────────
//  Interfaces — read from the two deployed contracts
// ─────────────────────────────────────────────────────────────

interface IAssignId {
    function isSensorRegistered(uint _sensorId) external view returns (bool);
    function sensors(uint _sensorId) external view returns (uint sensorId, string memory location, bool registered);
    function sensorCount() external view returns (uint);
}

interface IWeatherData {
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
    function getWeatherHistory(uint _sensorId) external view returns (WeatherRecord[] memory);
    function getLatestRecord(uint _sensorId)   external view returns (WeatherRecord memory);
    function getRecordCount(uint _sensorId)    external view returns (uint);
}

// ─────────────────────────────────────────────────────────────
//  viewRecordData
//  Read-only public query contract.
//  Anyone — a government agency, an insurer, a researcher —
//  can query by sensor ID, transaction hash, or date range
//  to retrieve stored hashes and cross-check them against
//  off-chain raw data. No special permissions required.
// ─────────────────────────────────────────────────────────────

contract viewRecordData {

    // References to the two live contracts
    IAssignId   public assignIdContract;
    IWeatherData public weatherDataContract;

    // Flat record returned to callers — includes decoded values
    // so external tools don't need to know the storage layout
    struct QueryResult {
        uint    sensorId;
        string  location;
        uint    rain;       // ×10  e.g. 12 = 1.2 mm
        uint    wind;       // ×10  e.g. 145 = 14.5 km/h
        uint    humidity;   // %
        uint    pressure;   // ×10  e.g. 10132 = 1013.2 hPa
        uint    temp;       // ×10  e.g. 231 = 23.1 °C
        uint    timestamp;  // Unix epoch
        bytes32 weatherHash;
        bool    verified;   // hash matches on-chain record (always true here — for cross-check UI)
    }

    event ContractsUpdated(address assignId, address weatherData);

    constructor(address _assignId, address _weatherData) {
        assignIdContract    = IAssignId(_assignId);
        weatherDataContract = IWeatherData(_weatherData);
        emit ContractsUpdated(_assignId, _weatherData);
    }

    // ─── Query by Sensor ID ───────────────────────────────────
    // Returns every record ever stored for that sensor
    function queryBySensorId(uint _sensorId)
        external view
        returns (QueryResult[] memory)
    {
        require(assignIdContract.isSensorRegistered(_sensorId), "Sensor not registered");

        IWeatherData.WeatherRecord[] memory raw = weatherDataContract.getWeatherHistory(_sensorId);
        (, string memory location, ) = assignIdContract.sensors(_sensorId);

        QueryResult[] memory results = new QueryResult[](raw.length);
        for (uint i = 0; i < raw.length; i++) {
            results[i] = _toQueryResult(raw[i], location);
        }
        return results;
    }

    // ─── Query Latest Record for a Sensor ────────────────────
    function queryLatest(uint _sensorId)
        external view
        returns (QueryResult memory)
    {
        require(assignIdContract.isSensorRegistered(_sensorId), "Sensor not registered");
        IWeatherData.WeatherRecord memory raw = weatherDataContract.getLatestRecord(_sensorId);
        (, string memory location, ) = assignIdContract.sensors(_sensorId);
        return _toQueryResult(raw, location);
    }

    // ─── Query by Date Range ─────────────────────────────────
    // Returns all records for a sensor between two Unix timestamps
    function queryByDateRange(uint _sensorId, uint _from, uint _to)
        external view
        returns (QueryResult[] memory)
    {
        require(_from < _to,  "Invalid date range");
        require(assignIdContract.isSensorRegistered(_sensorId), "Sensor not registered");

        IWeatherData.WeatherRecord[] memory raw = weatherDataContract.getWeatherHistory(_sensorId);
        (, string memory location, ) = assignIdContract.sensors(_sensorId);

        // Count matching records first (no dynamic arrays in memory)
        uint count = 0;
        for (uint i = 0; i < raw.length; i++) {
            if (raw[i].timestamp >= _from && raw[i].timestamp <= _to) count++;
        }

        QueryResult[] memory results = new QueryResult[](count);
        uint idx = 0;
        for (uint i = 0; i < raw.length; i++) {
            if (raw[i].timestamp >= _from && raw[i].timestamp <= _to) {
                results[idx] = _toQueryResult(raw[i], location);
                idx++;
            }
        }
        return results;
    }

    // ─── Verify a Hash ───────────────────────────────────────
    // Given a sensor ID and a hash, returns true if any record
    // stored for that sensor matches — used for cross-checking
    // against off-chain raw data files
    function verifyHash(uint _sensorId, bytes32 _hash)
        external view
        returns (bool found, uint recordIndex, uint timestamp)
    {
        require(assignIdContract.isSensorRegistered(_sensorId), "Sensor not registered");
        IWeatherData.WeatherRecord[] memory raw = weatherDataContract.getWeatherHistory(_sensorId);
        for (uint i = 0; i < raw.length; i++) {
            if (raw[i].weatherHash == _hash) {
                return (true, i, raw[i].timestamp);
            }
        }
        return (false, 0, 0);
    }

    // ─── Get record count ────────────────────────────────────
    function getRecordCount(uint _sensorId)
        external view
        returns (uint)
    {
        return weatherDataContract.getRecordCount(_sensorId);
    }

    // ─── Check if sensor is registered ──────────────────────
    function isSensorRegistered(uint _sensorId)
        external view
        returns (bool)
    {
        return assignIdContract.isSensorRegistered(_sensorId);
    }

    // ─── Get sensor location string ──────────────────────────
    function getSensorLocation(uint _sensorId)
        external view
        returns (string memory)
    {
        (, string memory location, ) = assignIdContract.sensors(_sensorId);
        return location;
    }

    // ─── Internal helper ─────────────────────────────────────
    function _toQueryResult(IWeatherData.WeatherRecord memory r, string memory location)
        internal pure
        returns (QueryResult memory)
    {
        return QueryResult({
            sensorId:    r.sensorId,
            location:    location,
            rain:        r.rain,
            wind:        r.wind,
            humidity:    r.humidity,
            pressure:    r.pressure,
            temp:        r.temp,
            timestamp:   r.timestamp,
            weatherHash: r.weatherHash,
            verified:    true
        });
    }
}
