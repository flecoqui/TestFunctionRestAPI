using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace TestFunctionApp
{
    public static class Constants
    {
        private static IConfiguration AppSettings;
        public static void Initialize(IConfiguration configuration)
        {
            AppSettings = configuration;
        }

        public static string MetricsPath { get { return AppSettings["METRICS_PATH"] ?? "metrics"; } }
        public static string ExposeHttpMetrics { get { return AppSettings["EXPOSE_HTTP_METRICS"] ?? "false"; } }
        public static string MetricsPrefix { get { return AppSettings["METRICS_PREFIX"] ?? "testfunction"; } }
    }
}
