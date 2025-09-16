using DoAnCoSo.Models;
using System.Collections.Generic;

namespace DoAnCoSo.ViewModels
{
    public class MasterViewModel
    {
        public IEnumerable<Category> Categories { get; set; }
        public IEnumerable<Product> Products { get; set; }
        public IEnumerable<Order> Orders { get; set; }
        public IEnumerable<Appointment> PendingAppointments { get; set; }
        public IEnumerable<Appointment> AppointmentHistory { get; set; }
        public int PendingAppointmentsCount { get; set; }
        public int ProcessedAppointmentsCount { get; set; }
        public IEnumerable<UserInfoViewModel> Users { get; set; }
        public string AppointmentStatusFilter { get; set; }
    }
}