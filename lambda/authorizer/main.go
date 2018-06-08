package main

import (
	"context"
	"errors"
	"regexp"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	lambda.Start(func(c context.Context, evt events.APIGatewayCustomAuthorizerRequest) (*events.APIGatewayCustomAuthorizerResponse, error) {
		token := regexp.MustCompile("(?:Bearer|Basic) (.*)").FindStringSubmatch(evt.AuthorizationToken)[1]
		if token == "deny" {
			return nil, errors.New("Unauthorized")
		}

		policy := events.APIGatewayCustomAuthorizerPolicy{
			Version: "2012-10-17",
			Statement: []events.IAMPolicyStatement{
				events.IAMPolicyStatement{
					Action:   []string{"execute-api:Invoke"},
					Effect:   "Allow",
					Resource: []string{evt.MethodArn},
				},
			},
		}
		return &events.APIGatewayCustomAuthorizerResponse{
			PrincipalID:    "some-id",
			PolicyDocument: policy,
		}, nil
	})
}
