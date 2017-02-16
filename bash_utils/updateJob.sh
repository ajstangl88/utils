#!/bin/bash
echo "Enter Job ID: "
read item
var1= $(echo $item | xargs -i cat /mnt/projects/clovr/output_repository/run_command/{}_runpipeline/runpipeline.out | xargs -i echo "db.tasks.update({'name':'{}'},{"'$set'" : {'state': 'completed'}})")
bash -c "echo 'use mongo clover' > test.js"
bash -c "echo $var1 >> test.js"
#bash -c "mongo clover test.sj"

echo "6646"| xargs -i cat /mnt/projects/pgs/output_repository/run_command/{}_runpipeline/runpipeline.out | xargs -i echo "db.tasks.update({'name':'{}'},{"'$set'" : {'state': 'completed'}})"
echo "6646" | xargs -i cat /mnt/projects/pgs/output_repository/run_command/{}_runpipeline/runpipeline.out | xargs -i echo "db.tasks.update({'name':'{}'},{"'$set'" : {'state': 'completed'}})"