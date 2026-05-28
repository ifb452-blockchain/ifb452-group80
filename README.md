IFB452 Group 80 IoT Weather Observation Blockchain Project

# Project overview 

Table of Contents:
1.1	Project Overview
1.2	How to run
1.3	Contracts
1.4	Features
1.5	Limitations
1.6	Improvements
1.7	References
1.2 HOW TO RUN:
Step 0:
Navigate to the root directory of the project in your terminal and host locally using python with the command below (or utilise an alternative method):
python -m http.server 8080
Once the server is running head to http://localhost:8080/enlil_dashboard.html 

Step 1: Compile assignId.sol

Step 2: Compile weatherData.sol

Step 3: Switch to "Browser Wallet"

Step 4: Connect MetaMask wallet

Step 5: CONTRACT -> assignId

Step 6: Deploy 

Step 7: Confirm in MetaMask

Step 8: Check deployed contracts for address in 'deployed contracts' and copy address for weatherData

Step 9: Change 'contract' to weatherData

Step 10: _sensorRegistered: input copied address

Step 11: Deploy and confirm on MetaMask

Step 12: Check deployed contracts 

Register a sensor:

Step 1: go to 'registerSensor' and enter values and transact, confirm in MetaMask, wait for transaction to complete.

Step 2: expand weatherData and find recordWeatherData and enter parameters, click 'transact', confirm in MetaMask

View the stored data: 

Step 1: go to 'getLatestRecord' in weatherData and enter values, click 'call' and view weather

Check record count: 

Step 1: go to getRecordCount and enter a sensor Id, click call, view returned data.


(NOT NECESSARY BUT DOABLE) 

Step 1: in assignId contract, go to 'addTechnician'
Step 2: select address from drop down
Step 3: transact

(to swap to technician wallet)
Step 1: MetaMask, change account to 'Account 2'
Step 2: Remix detects the change
Step 3: Can now register another sensor using the tech wallet


Techstack:
API used to imitate accurate locational data from physical sensors: https://open-meteo.com/en/docs 
Documentation on how to use the API are above and will be ideally replaced in future by the implementation of physical weather sensors.
Solidity version (^0.8.0):
Not chosen for any particular reason, just used as it sufficed for our needs.
Python localhost:
python -m http.server 8080

# What it is, what it should do, why is it needed?
- Enlil is a weather observation application. Connected via LoRaWAN, an array of sensors captures weather events in strategic locations. By combining a decentralised application (dApp) with real-world weather observations, Enlil aims to provide accurate and immutable historical weather data that can be used by different stakeholders to inform policy decisions. The goal was to introduce an immutable record of historical weather trends to accurately predict and mitigate future adverse weather events. 

# Who are the stakeholders?
- Network Technicians responsible for deployment of software on infrastructure.
- Stakeholders for this project would be anybody with an interest in tracking 	weather events. The stakeholders who would be the main beneficiaries of this project would be Government agencies (such as the Department of Natural Resources and Mines, Manufacturing and Regional and Rural Development), insurance companies (actuaries, in particular) due to their need for uncompromised and verifiable data.

# Why a blockchain? 
- Due to the need for transparency within Government and, less so, insurance agencies, a blockchain provides an easy way for multiple stakeholders to verify and utilise any recorded data. The project uses a Public Permissioned Blockchain due to the nature of the recordings coming from multiple different sources. Through the utilisation of this specific type of blockchain we minimise the chance that a malicious actor could alter weather recordings surreptitiously. 



# Contracts: 
- assignId: This smart contract is used to assign a unique identifier (Id) to each of the sensors. When the smart contract is deployed the owner (Technician) can register sensors to record weather observations. 
- weatherData: This smart contract utilises the address of the owner from the `assignId` smart contract to ensure only sensors registered can contribute weather observations. The `weatherData` contract also provides the option to access recorded weather history as well as sending the hashed weather observations to the blockchain. 
 - viewrecordData: This smart contract acts as a central aggregator that allows users to query and verify climate data by interfacing with two separate deployed contracts for sensor registration and weather logging. It provides various public functions to retrieve historical weather records, including rainfall, wind, and temperature, based on specific sensor IDs or custom date ranges. Beyond data retrieval, the contract includes a hash verification feature that enables external parties to cross check off chain database data against the cryptographically secured on chain records. By formatting raw data into a readable structure, it serves as a transparent, permissionless gateway for government agencies, insurers or researchers to audit environmental sensor data.
		
# Limitations:
- Api data in place of real-world observations, as we couldn’t deploy real-world sensors to record weather observations, we instead used an API to simulate the necessary data. -  No database to store and recall weather data, meant that while we did have simulated weather observations for the dashboard, we unfortunately could not provide a database to store readings. In the live production version of this project a database to record and store weather observations to is necessary. Without the database our project lacks the ability to recall more than the previously stored weather observations. 
- Because we had no access to an oracle service, such as Chainlink, the project requires that everything be started manually, although ultimately the goal would be total automation after initial deployment by the Technicians.
- In conceptual stages the goal was to be able batch deploy these smart contracts to save time, but we soon realised that would be impractical as each of the sensors need a single owner to ensure validity of weather recordings. 
		
# Improvements:
- The project could be improved by connecting a database to the back end so that recordings can be stored and retrieved to verify transactions. Currently limited to viewing only the most recent, as a proof-of-concept.  
- Deploying real-world sensors instead of using API data would be the ideal situation for this project as using API data is only adequate for this proof-of-concept project.
# Store weather hashes / recording on IFPS network (think you mentioned it above? I can write more about it here if not.) 
Tutor Feedback:
Upon feedback from the progress implementation, it has come to our attention that having all the off-chain data stored onto the database is a major issue as it is a single point of failure. Therefore, following our feedback it is advised that in future implementations of this application you would utilise a portion of the data servers’ resources to contributing to the IPFS project (https://ipfs.tech/) as it would allow the most important in demand data to be accessed and protected in the event of the off chain system’s failure.
