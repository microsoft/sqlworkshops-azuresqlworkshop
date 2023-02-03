# Special Edition Module for Performance Troubleshooting

This is a special edition module for performance troubleshooting. This module is intended to be used as advanced module and take after going through all the other 6 modules for the Azure SQL Workshop.

The scripts in this module accompany the Azure SQL for Beginners Special Edition on Performance Troubleshooting: https://aka.ms/azuresql4beginners

This module contains the following scenarios which can be taken independent of each other:

## High CPU due to a missing index

This scenario involves a performance problem seen by high CPU due to a missing index for a query. To go through this scenario, follow the instructions in the [highcpu_missingindex](highcpu_missingindex/readme.md) folder.

## High CPU due to antipattern queries

This scenario involves a performance problem seen by high CPU due to an antipattern query. To go through this scenario, follow the instructions in the [highcpu_antipattern](highcpu_antipattern/readme.md) folder.

## High CPU due to lack of resources

This scenario involves a performance problem seen by high CPU due to lack of CPU resources. To go through this scenario, follow the instructions in the [highcpu_lackofresources](highcpu_lackofresources/readme.md) folder.

## Waiting due to blocking

This scenario involves a performance problem seen by little or no CPU resources but performance is slow due to a blocking problem between different SQL requests. To go through this scenario, follow the instructions in the [waiting_blocking](waiting_blocking/readme.md) folder.

## Waiting due to deadlocks

This scenario involves a performance problem seen by little or no CPU resources but performance is slow due to deadlocks between different SQL transactions. To go through this scenario, follow the instructions in the [waiting_deadlocks](waiting_deadlocks/readme.md) folder.

## Waiting due to memory grants

This scenario involves a performance problem seen by some or low CPU but performance is slow due to a high need for memory grants for several SQL concurrent queries. To go through this scenario, follow the instructions in the [waiting_memorygrant](waiting_memorygrant/readme.md) folder.