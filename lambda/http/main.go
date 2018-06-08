package main

import (
	"context"
	"fmt"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	lambda.Start(func(c context.Context, evt events.APIGatewayProxyRequest) (*events.APIGatewayProxyResponse, error) {
		fmt.Printf("%#+v", evt)
		return &events.APIGatewayProxyResponse{
			Body:       `{"message":"Hello World!"}`,
			StatusCode: http.StatusOK,
		}, nil
	})
}
