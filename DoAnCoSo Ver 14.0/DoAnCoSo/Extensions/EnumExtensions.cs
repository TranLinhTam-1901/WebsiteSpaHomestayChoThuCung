using System;
using System.ComponentModel.DataAnnotations;
using System.Reflection;

namespace DoAnCoSo.Extensions
{
    //public static string GetDisplayName(this Enum enumValue)
    //{
    //    return enumValue.GetType()
    //        .GetMember(enumValue.ToString())
    //        .First()
    //        .GetCustomAttribute<DisplayAttribute>()
    //        ?.Name ?? enumValue.ToString();
    //}

    public static class EnumExtensions
    {
        public static string GetDisplayName(this Enum value)
        {
            var field = value.GetType().GetField(value.ToString());
            var attribute = field.GetCustomAttribute<DisplayAttribute>();
            return attribute?.Name ?? value.ToString();
        }
    }
}

