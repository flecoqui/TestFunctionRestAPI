using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

using System.Collections;
using System.Threading;

namespace TestFunctionApp.Controllers
{


    [Route("api/[controller]")]
    [ApiController]
    public class TestController : ControllerBase
    {
        // GET api/test
        [HttpGet]
        public JsonResult Get()
        {

            //return "[{\"value\": \"1\"},{\"value\": \"2\"}]";
            return new JsonResult(new List<TestResponse>
            {
                new TestResponse {name="HttpPostTimerMs", value=ValuesController.HttpPostTimer.ToString()},
                new TestResponse {name="HttpPostCounter", value=ValuesController.HttpPostCounter.ToString()},
                new TestResponse {name="HttpPostStartTime", value=ValuesController.HttpPostStartTime.ToString()},
                new TestResponse {name="HttpPostEndTime", value=ValuesController.HttpPostEndTime.ToString()}

            });
        }
        // DELETE api/test/
        [HttpDelete]
        public JsonResult Delete()
        {
            ValuesController.HttpPostTimer = 0;
            ValuesController.HttpPostCounter = 0;
            ValuesController.HttpPostStartTime = DateTime.MinValue;
            ValuesController.HttpPostEndTime = DateTime.MinValue;
            return new JsonResult(new List<TestResponse>
            {
                new TestResponse {name="HttpPostTimerMs", value=ValuesController.HttpPostTimer.ToString()},
                new TestResponse {name="HttpPostCounter", value=ValuesController.HttpPostCounter.ToString()},
                new TestResponse {name="HttpPostStartTime", value=ValuesController.HttpPostStartTime.ToString()},
                new TestResponse {name="HttpPostEndTime", value=ValuesController.HttpPostEndTime.ToString()}

            });
        }
    }
}
