using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;

namespace TestFunctionApp
{
    public static class TestController
    {

        [FunctionName("test")]


        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "delete", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");
            if (req.Method.ToLower() == "get")
                return await Task.FromResult(new JsonResult(new List<TestResponse>
            {
                new TestResponse {name="HttpTimerMs", value=ValuesController.HttpTimer.ToString()},
                new TestResponse {name="HttpCounter", value=ValuesController.HttpCounter.ToString()},
                new TestResponse {name="HttpStartTime", value=ValuesController.HttpStartTime.ToString()},
                new TestResponse {name="HttpEndTime", value=ValuesController.HttpEndTime.ToString()}

            }));
            else if (req.Method.ToLower() == "delete")
            {
                ValuesController.HttpTimer = 0;
                ValuesController.HttpCounter = 0;
                ValuesController.HttpStartTime = DateTime.MinValue;
                ValuesController.HttpEndTime = DateTime.MinValue;
                return await Task.FromResult(new JsonResult(new List<TestResponse>
                {
                    new TestResponse {name="HttpTimerMs", value=ValuesController.HttpTimer.ToString()},
                    new TestResponse {name="HttpCounter", value=ValuesController.HttpCounter.ToString()},
                    new TestResponse {name="HttpStartTime", value=ValuesController.HttpStartTime.ToString()},
                    new TestResponse {name="HttpEndTime", value=ValuesController.HttpEndTime.ToString()}

                }));
            }
            return null;

        }
    }

}
