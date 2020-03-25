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
    public class HttpTimer : IDisposable
    {
        DateTime start;
        public HttpTimer()
        {
            start = DateTime.Now;
            if (ValuesController.HttpStartTime == DateTime.MinValue)
                ValuesController.HttpStartTime = start;
        }
        public void Dispose()
        {
            ValuesController.HttpEndTime = DateTime.Now;
            TimeSpan ts = ValuesController.HttpEndTime - start;
            ValuesController.HttpCounter++;
            ValuesController.HttpTimer += ts.TotalMilliseconds;
        }

    }
    public class TestResponse
    {
        public string name { get; set; }
        public string value { get; set; }

    };
    public static class ValuesController
    {
        public static double HttpCounter;
        public static double HttpTimer;
        public static DateTime HttpStartTime = DateTime.MinValue;
        public static DateTime HttpEndTime = DateTime.MinValue;
        [FunctionName("values")]

        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post","get", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");
            string name = string.Empty;

            try
            {
                name = req.Query["name"];
            }
            catch(Exception)
            {

            }
            if(string.IsNullOrEmpty(name))
            {
                try
                {
                    // Read body
                    string value = new StreamReader(req.Body).ReadToEnd();
                    dynamic inputdata = JsonConvert.DeserializeObject(value);
                    name = name ?? inputdata?.name;
                }
                catch (Exception)
                {

                }
            }
            if (!string.IsNullOrEmpty(name))
            {
                using (HttpTimer hpt = new HttpTimer())
                {
                    TestResponse t = new TestResponse();
                    t.name = "testResponse";
                    t.value = name.ToString();
                    return await Task.FromResult(new JsonResult(t));
                }
            }
            return new BadRequestResult();
        }
    }

}
