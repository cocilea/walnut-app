// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Walnut} from "../src/Walnut.sol";

contract WalnutTest is Test {
    Walnut public walnut;

    function setUp() public {
        // Initialize a Walnut with shell strength = 2 and kernel = 0
        walnut = new Walnut(2, suint256(0));
    }
    
    function test_Hit() public {
    walnut.hit(); // Decrease shell strength by 1
    walnut.hit(); // Fully crack the shell
    assertEq(walnut.look(), 0); // Kernel should still be 0 since no shakes
    }
    
    function test_CannotHitWhenCracked() public {
    walnut.hit(); // Decrease shell strength by 1
    walnut.hit(); // Fully crack the shell
    vm.expectRevert("SHELL_ALREADY_CRACKED"); // Expect revert when hitting an already cracked shell
    walnut.hit();
    }
    
    function test_Shake() public {
    walnut.shake(suint256(10)); // Shake the Walnut, increasing the kernel
    walnut.hit(); // Decrease shell strength by 1
    walnut.hit(); // Fully crack the shell
    assertEq(walnut.look(), 10); // Kernel should be 10 after 10 shakes
    }
    
    function test_CannotShakeWhenCracked() public {
    walnut.hit(); // Decrease shell strength by 1
    walnut.shake(suint256(1)); // Shake the Walnut
    walnut.hit(); // Fully crack the shell
    vm.expectRevert("SHELL_ALREADY_CRACKED"); // Expect revert when shaking an already cracked shell
    walnut.shake(suint256(1));
    }
    
    function test_Reset() public {
    walnut.hit(); // Decrease shell strength by 1
    walnut.shake(suint256(2)); // Shake the Walnut
    walnut.hit(); // Fully crack the shell
    walnut.reset(); // Reset the Walnut

    assertEq(walnut.getShellStrength(), 2); // Shell strength should reset to initial value
    walnut.hit(); // Start hitting again
    walnut.shake(suint256(5)); // Shake the Walnut again
    walnut.hit(); // Fully crack the shell again
    assertEq(walnut.look(), 5); // Kernel should reflect the shakes in the new round
    }
    
    function test_CannotLookWhenIntact() public {
    walnut.hit(); // Partially crack the shell
    walnut.shake(suint256(1)); // Shake the Walnut
    vm.expectRevert("SHELL_INTACT"); // Expect revert when trying to look at the kernel with the shell intact
    walnut.look();
    }
    
    function test_CannotResetWhenIntact() public {
    walnut.hit(); // Partially crack the shell
    walnut.shake(suint256(1)); // Shake the Walnut
    vm.expectRevert("SHELL_INTACT"); // Expect revert when trying to reset without cracking the shell
    walnut.reset();
    }
    
    function test_ManyActions() public {
    uint256 shakes = 0;
    for (uint256 i = 0; i < 50; i++) {
        if (walnut.getShellStrength() > 0) {
            if (i % 25 == 0) {
                walnut.hit(); // Hit the shell every 25 iterations
            } else {
                uint256 numShakes = (i % 3) + 1; // Random shakes between 1 and 3
                walnut.shake(suint256(numShakes));
                shakes += numShakes;
            }
        }
    }
    assertEq(walnut.look(), shakes); // Kernel should match the total number of shakes
    }
    
    function test_RevertWhen_NonContributorTriesToLook() public {
    address nonContributor = address(0xabcd);

    walnut.hit(); // Decrease shell strength by 1
    walnut.shake(suint256(3)); // Shake the Walnut
    walnut.hit(); // Fully crack the shell

    vm.prank(nonContributor); // Impersonate a non-contributor
    vm.expectRevert("NOT_A_CONTRIBUTOR"); // Expect revert when non-contributor calls `look()`
    walnut.look();
    }
    
    function test_ContributorInRound2() public {
    address contributorRound2 = address(0xabcd); // Contributor for round 2

    // Round 1: Cracked by address(this)
    walnut.hit(); // Hit 1
    walnut.hit(); // Hit 2
    assertEq(walnut.look(), 0); // Confirm kernel value

    walnut.reset(); // Start Round 2

    // Round 2: ContributorRound2 cracks the Walnut
    vm.prank(contributorRound2);
    walnut.hit();

    vm.prank(contributorRound2);
    walnut.shake(suint256(5)); // Shake kernel 5 times

    vm.prank(contributorRound2);
    walnut.hit();

    vm.prank(contributorRound2);
    assertEq(walnut.look(), 5); // Kernel value is 5 for contributorRound2

    vm.expectRevert("NOT_A_CONTRIBUTOR"); // address(this) cannot look in round 2
    walnut.look();
    }
    
}
