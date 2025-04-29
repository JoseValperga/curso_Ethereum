//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

// declaring a struct type outsite of a contract
// can be used in any contract declard in this file
struct Instructor {
    uint256 age;
    string name;
    address addr;
}

contract Academy {
    // declaring a state variabla of type Instructor
    Instructor public academyInstructor;

    // declaring a new enum type
    enum State {
        Open,
        Closed,
        Unknown
    }

    // declaring and initializing a new state variable of type State
    State public academyState = State.Open;

    // initializing the struct in the constructor
    constructor(uint256 _age, string memory _name) {
        academyInstructor.age = _age;
        academyInstructor.name = _name;
        academyInstructor.addr = msg.sender;
    }

    // changing a struct state variable
    function changeInstructor(
        uint256 _age,
        string memory _name,
        address _addr
    ) public {
        if (academyState == State.Open) {
            Instructor memory myInstructor = Instructor({
                age: _age,
                name: _name,
                addr: _addr
            });
            academyInstructor = myInstructor;
        }
    }
    
    //changing academyState
    function changeState(uint newState) public {
        academyState = State(newState);
    } 
}

// the struct can be used in any contract declared in this file
contract School {
    Instructor public schoolInstructor;
}
