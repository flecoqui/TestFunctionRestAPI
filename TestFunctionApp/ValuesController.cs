using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace TestFunctionApp
{
    public class HttpPostTimer : IDisposable
    {
        DateTime start;
        public HttpPostTimer()
        {
            start = DateTime.Now;
            if (ValuesController.HttpPostStartTime == DateTime.MinValue)
                ValuesController.HttpPostStartTime = start;
        }
        public void Dispose()
        {
            ValuesController.HttpPostEndTime = DateTime.Now;
            TimeSpan ts = ValuesController.HttpPostEndTime - start;
            ValuesController.HttpPostCounter++;
            ValuesController.HttpPostTimer += ts.TotalMilliseconds;
        }

    }
    public class TestResponse
    {
        public string name { get; set; }
        public string value { get; set; }

    };
    public static class ValuesController
    {
        public static double HttpPostCounter;
        public static double HttpPostTimer;
        public static DateTime HttpPostStartTime = DateTime.MinValue;
        public static DateTime HttpPostEndTime = DateTime.MinValue;
        [FunctionName("values")]

        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            //log.LogInformation("C# HTTP trigger function processed a request.");            

            string value = new StreamReader(req.Body).ReadToEnd();
            dynamic inputdata = JsonConvert.DeserializeObject(value);

            if (inputdata != null)
            {
                using (HttpPostTimer hpt = new HttpPostTimer())
                {
                    TestResponse t = new TestResponse();
                    t.name = "testResponse";
                    t.value = inputdata.ToString();
                    return await Task.FromResult(new JsonResult(t));
                }
            }
            return new BadRequestResult();
        }
    }

}
