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

        public static string MetricsPath { get {
                string s = AppSettings["METRICS_PATH"] ?? "metrics";
                return s.Trim('"');
            }
        }
        public static string ExposeHttpMetrics { get {
                string s = AppSettings["EXPOSE_HTTP_METRICS"] ?? "false";
                return s.Trim('"');
            }
        }
        public static string MetricsPrefix { get { 
                        string s = AppSettings["METRICS_PREFIX"] ?? "testfunction";
                        return s.Trim('"');
                        } }
    }
}
