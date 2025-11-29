// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PawHouse {
    struct Record {
        uint id;
        string dataJson;
    }

    Record[] public records;

    function addRecord(string memory dataJson) public {
        records.push(Record(records.length, dataJson));
    }

    function getRecordsCount() public view returns (uint) {
        return records.length;
    }

    function getRecord(uint index) public view returns (uint, string memory) {
        require(index < records.length, "Index out of range");
        Record memory r = records[index];
        return (r.id, r.dataJson);
    }
}
