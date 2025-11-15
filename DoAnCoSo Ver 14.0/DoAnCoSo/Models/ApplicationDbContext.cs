<<<<<<< HEAD
﻿using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
=======
﻿using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using DoAnCoSo.Models;
>>>>>>> 47478e8a4d766272fbd7162d63193bbd37bf0b5e

namespace DoAnCoSo.Models
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderDetail> OrderDetails { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<ProductImage> ProductImages { get; set; }

        public DbSet<Pet> Pets { get; set; }
        public DbSet<PetServiceRecord> PetServiceRecords { get; set; }

        public DbSet<Appointment> Appointments { get; set; }
        public DbSet<Service> Services { get; set; }
        public DbSet<SpaPricing> SpaPricings { get; set; }

        public DbSet<Review> Reviews { get; set; }
        public DbSet<ReviewImage> ReviewImages { get; set; }  // 🔹 thay ProductReviewImage

        public DbSet<Payment> Payments { get; set; }
        public DbSet<Invoice> Invoices { get; set; }
        public DbSet<Favorite> Favorites { get; set; }

        public DbSet<CartItem> CartItems { get; set; }

        public DbSet<ChatMessage> ChatMessages { get; set; }
        public DbSet<Conversation> Conversations { get; set; }
        public DbSet<SystemState> SystemStates { get; set; }
        public DbSet<ChatImage> ChatImages { get; set; }

        public DbSet<Promotion> Promotions { get; set; }

        public DbSet<OrderPromotion> OrderPromotions { get; set; }
        public DbSet<UserPromotion> UserPromotions { get; set; }

        public DbSet<DoAnCoSo.Models.Blockchain.BlockchainRecord> BlockchainRecords { get; set; }

        public DbSet<DeletedPets> DeletedPets { get; set; }
        public DbSet<InventoryLog> InventoryLogs { get; set; }
        public DbSet<ProductVariant> ProductVariants { get; set; }



        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder); // Identity config

            // 🔹 Appointment.Status enum -> string
            modelBuilder.Entity<Appointment>()
                .Property(a => a.Status)
                .HasConversion<string>();

            // 🔹 Appointment - Pet
            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.Pet)
                .WithMany()
                .HasForeignKey(a => a.PetId)
                .OnDelete(DeleteBehavior.SetNull); // hoặc DeleteBehavior.Cascade

            modelBuilder.Entity<PetServiceRecord>()
                .HasKey(r => r.RecordId);

            modelBuilder.Entity<PetServiceRecord>()
                .HasOne(r => r.Pet)
                .WithMany(p => p.ServiceRecords)
                .HasForeignKey(r => r.PetId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<PetServiceRecord>()
                .HasOne(r => r.Service)
                .WithMany(s => s.PetServiceRecords)
                .HasForeignKey(r => r.ServiceId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 Appointment - Service
            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.Service)
                .WithMany(s => s.Appointments)
                .HasForeignKey(a => a.ServiceId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 Appointment - User
            modelBuilder.Entity<Appointment>()
                .HasOne(a => a.User)
                .WithMany()
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 Payment - Order
            modelBuilder.Entity<Payment>()
                .HasOne(p => p.Order)
                .WithMany(o => o.Payments)
                .HasForeignKey(p => p.OrderId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 Invoice - Order
            modelBuilder.Entity<Invoice>()
                .HasOne(i => i.Order)
                .WithMany(o => o.Invoices)
                .HasForeignKey(i => i.OrderId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 ChatMessage - Sender
            modelBuilder.Entity<ChatMessage>()
                .HasOne(m => m.Sender)
                .WithMany()
                .HasForeignKey(m => m.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 ChatMessage - Receiver
            modelBuilder.Entity<ChatMessage>()
                .HasOne(m => m.Receiver)
                .WithMany()
                .HasForeignKey(m => m.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 Conversation - Customer
            modelBuilder.Entity<Conversation>()
                .HasOne(c => c.Customer)
                .WithMany()
                .HasForeignKey(c => c.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 Conversation - Admin
            modelBuilder.Entity<Conversation>()
                .HasOne(c => c.Admin)
                .WithMany()
                .HasForeignKey(c => c.AdminId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 Review - ReviewImage (1-nhiều)
            modelBuilder.Entity<ReviewImage>()
                .HasOne(ri => ri.Review)
                .WithMany(r => r.Images)
                .HasForeignKey(ri => ri.ReviewId)
                .OnDelete(DeleteBehavior.Cascade);

            // ✅ Thêm phần unique constraint cho UserPromotion tại đây:
            modelBuilder.Entity<UserPromotion>()
                .HasIndex(up => new { up.UserId, up.PromotionId })
                .IsUnique();
            // Thêm phần unique constraint cho UserPromotion tại đây:
            modelBuilder.Entity<UserPromotion>()
                .HasIndex(up => new { up.UserId, up.PromotionId })
                .IsUnique();

            modelBuilder.Entity<InventoryLog>()
                .HasOne(l => l.Product)
                .WithMany()
                .HasForeignKey(l => l.ProductId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ProductVariant>(b =>
            {
                b.HasKey(v => v.Id);
                b.HasIndex(v => new { v.ProductId, v.Name }).IsUnique(); // Mỗi sản phẩm, tên biến thể không trùng
                b.Property(v => v.Name).HasMaxLength(200).IsRequired();

                b.HasOne(v => v.Product)
                 .WithMany(p => p.Variants) // => nhớ thêm ICollection<ProductVariant> Variants trong Product nếu bạn muốn
                 .HasForeignKey(v => v.ProductId)
                 .OnDelete(DeleteBehavior.Cascade);
            });

            // Log có thể tham chiếu variant
            modelBuilder.Entity<InventoryLog>(b =>
            {
                b.HasIndex(l => l.VariantId);
            });

            // OrderDetail/CartItem: chỉ cần cột VariantId nullable, FK có thể cấu hình nếu muốn:
            modelBuilder.Entity<OrderDetail>()
                .HasOne<ProductVariant>()
                .WithMany()
                .HasForeignKey(od => od.VariantId)
                .OnDelete(DeleteBehavior.Restrict); // tránh xóa nhầm variant gây mất lịch sử

            modelBuilder.Entity<CartItem>()
                .HasOne<ProductVariant>()
                .WithMany()
                .HasForeignKey(ci => ci.VariantId)
                .OnDelete(DeleteBehavior.Restrict);


        }
    }
}
