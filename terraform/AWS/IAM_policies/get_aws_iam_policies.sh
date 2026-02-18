#!/bin/sh

export AWS_PROFILE=practical-task

aws configure --profile practical-task

for POLICY in `aws iam list-policies --output text | grep Terraform | awk -F " " '{print $2"_"$5"_"$10}'`
do
	PARAMS=`echo ${POLICY} | awk -F "_" '{printf "--policy-arn "$1" --version-id "$2}'`
	OUTPUT_NAME_FILE=`echo ${POLICY} | awk -F "_" '{printf $3"_"$2}'`.txt
	
	echo "aws iam get-policy-version ${PARAMS} ${OUTPUT_NAME_FILE} \n"
	echo -e "aws iam get-policy-version ${PARAMS}\n" > ${OUTPUT_NAME_FILE}
	aws iam get-policy-version ${PARAMS} >> ${OUTPUT_NAME_FILE}
	read popo
done

ls -ltr 

