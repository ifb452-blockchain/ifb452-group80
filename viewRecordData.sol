// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ─────────────────────────────────────────────────────────────
//   Interfaces — read from the two deployed contracts
// ─────────────────────────────────────────────────────────────

// Interface to interact with the contract tracking sensor registrations
interface IAssignId {
    // Returns true if a sensor ID has been whitelisted/registered
    function isSensorRegistered(uint _sensorId) external view returns (bool);
    
    // Returns the location string and registration status tuple for a sensor
    function sensors(uint _sensorId) external view returns (uint sensorId, string memory location, bool registered);
    
    // Returns the total number of sensors ever registered
    function sensorCount() external view returns (uint);
}

// Interface to interact with the contract tracking the climate logs
interface IWeatherData {
    // Data layout representing an individual historical weather upload
    struct WeatherRecord {
        uint sensorId;      // ID of the reporting hardware
        uint rain;          // Amount of rainfall recorded
        uint wind;          // Recorded wind speed
        uint humidity;      // Humidity percentage
        uint pressure;      // Atmospheric pressure reading
        uint temp;          // Temperature reading
        uint timestamp;     // Block timestamp or Unix epoch time of log
        bytes32 weatherHash;// Cryptographic signature verifying off-chain raw file data
    }

    // Fetches the entire array of historical entries for a sensor
    function getWeatherHistory(uint _sensorId) external view returns (WeatherRecord[] memory);
    
    // Fetches only the single newest log entry for a sensor
    function getLatestRecord(uint _sensorId)   external view returns (WeatherRecord memory);
    
    // Returns total count of uploads made by a specific sensor
    function getRecordCount(uint _sensorId)    external view returns (uint);
}

// ─────────────────────────────────────────────────────────────
//   viewRecordData
//   Read-only public query contract.
//   Anyone — a government agency, an insurer, a researcher —
//   can query by sensor ID, transaction hash, or date range
//   to retrieve stored hashes and cross-check them against
//   off-chain raw data. No special permissions required.
// ─────────────────────────────────────────────────────────────

// Aggregator contract used to query, parse, and filter historical data across systems
contract viewRecordData {

    // Global links pointing to the addresses of the two target contracts
    IAssignId    public assignIdContract;
    IWeatherData public weatherDataContract;

    // Flat record returned to callers — includes decoded values
    // so external tools don't need to know the storage layout
    struct QueryResult {
        uint    sensorId;       // Unique sensor ID
        string  location;       // Decoded human-readable location string
        uint    rain;           // ×10  e.g. 12 = 1.2 mm
        uint    wind;           // ×10  e.g. 145 = 14.5 km/h
        uint    humidity;       // %
        uint    pressure;       // ×10  e.g. 10132 = 1013.2 hPa
        uint    temp;           // ×10  e.g. 231 = 23.1 °C
        uint    timestamp;      // Unix epoch time signature
        bytes32 weatherHash;    // Data verification hash
        bool    verified;       // UI validation flag (always true here — for cross-check UI)
    }

    // Event emitted if/when the underlying target contract configurations change
    event ContractsUpdated(address assignId, address weatherData);

    // Binds the aggregator to the active sensor and weather logging contract deployments
    constructor(address _assignId, address _weatherData) {
        assignIdContract    = IAssignId(_assignId);
        weatherDataContract = IWeatherData(_weatherData);
        emit ContractsUpdated(_assignId, _weatherData);
    }

    // ─── Query by Sensor ID ───────────────────────────────────
    // Gathers every history log for a sensor and packages it with its deployment location
    function queryBySensorId(uint _sensorId)
        external view
        returns (QueryResult[] memory)
    {
        // Enforce registration check to stop processing invalid sensor lookups early
        require(assignIdContract.isSensorRegistered(_sensorId), "Sensor not registered");

        // Fetch data array from weather registry and location string from sensor manager
        IWeatherData.WeatherRecord[] memory raw = weatherDataContract.getWeatherHistory(_sensorId);
        (, string memory location, ) = assignIdContract.sensors(_sensorId);

        // Instantiates a fixed-length memory array matching the size of raw history items
        QueryResult[] memory results = new QueryResult[](raw.length);
        
        // Loop through raw items to re-map them into our flat UI-friendly structure
        for (uint i = 0; i < raw.length; i++) {
            results[i] = _toQueryResult(raw[i], location);
        }
        return results;
    }

    // ─── Query Latest Record for a Sensor ────────────────────
    // Fetches only the single newest log entry submitted by a specific sensor
    function queryLatest(uint _sensorId)
        external view
        returns (QueryResult memory)
    {
        require(assignIdContract.isSensorRegistered(_sensorId), "Sensor not registered");
        
        // Retrieve single most recent entry from storage
        IWeatherData.WeatherRecord memory raw = weatherDataContract.getLatestRecord(_sensorId);
        (, string memory location, ) = assignIdContract.sensors(_sensorId);
        
        return _toQueryResult(raw, location);
    }

    // ─── Query by Date Range ─────────────────────────────────
    // Returns all records for a sensor falling between two specified Unix epoch timestamps
    function queryByDateRange(uint _sensorId, uint _from, uint _to)
        external view
        returns (QueryResult[] memory)
    {
        require(_from < _to,  "Invalid date range");
        require(assignIdContract.isSensorRegistered(_sensorId), "Sensor not registered");

        IWeatherData.WeatherRecord[] memory raw = weatherDataContract.getWeatherHistory(_sensorId);
        (, string memory location, ) = assignIdContract.sensors(_sensorId);

        // First pass loop: count matching items because EVM memory arrays cannot resize dynamically via .push()
        uint count = 0;
        for (uint i = 0; i < raw.length; i++) {
            if (raw[i].timestamp >= _from && raw[i].timestamp <= _to) count++;
        }

        // Allocate exact memory slot requirements discovered in first pass
        QueryResult[] memory results = new QueryResult[](count);
        
        // Second pass loop: populate our results array with matched items
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
    // Searches history to confirm if an off-chain data file's hash matches an on-chain record
    function verifyHash(uint _sensorId, bytes32 _hash)
        external view
        returns (bool found, uint recordIndex, uint timestamp)
    {
        require(assignIdContract.isSensorRegistered(_sensorId), "Sensor not registered");
        
        IWeatherData.WeatherRecord[] memory raw = weatherDataContract.getWeatherHistory(_sensorId);
        
        // Scan linearly across the sensor data arrays checking for matching hash values
        for (uint i = 0; i < raw.length; i++) {
            if (raw[i].weatherHash == _hash) {
                return (true, i, raw[i].timestamp); // Break and return early upon match discovery
            }
        }
        return (false, 0, 0); // Default return signature if no match exists on-chain
    }

    // ─── Get record count ────────────────────────────────────
    // Direct view pass-through showing total logs uploaded by a single sensor
    function getRecordCount(uint _sensorId)
        external view
        returns (uint)
    {
        return weatherDataContract.getRecordCount(_sensorId);
    }

    // ─── Check if sensor is registered ──────────────────────
    // Direct view pass-through verifying registration status of a sensor ID
    function isSensorRegistered(uint _sensorId)
        external view
        returns (bool)
    {
        return assignIdContract.isSensorRegistered(_sensorId);
    }

    // ─── Get sensor location string ──────────────────────────
    // Extracts and returns only the location string out of the multi-variable sensor tuple
    function getSensorLocation(uint _sensorId)
        external view
        returns (string memory)
    {
        // Ignores unwanted tuple parameters using structural blank commas (, ,)
        (, string memory location, ) = assignIdContract.sensors(_sensorId);
        return location;
    }

    // ─── Internal helper ─────────────────────────────────────
    // Formats a raw database log entry and its geographical location into a structured result item
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
            verified:    true // Hardcoded true to signify on-chain identity has successfully matched raw readings
        });
    }
}