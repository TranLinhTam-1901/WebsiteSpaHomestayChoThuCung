using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DoAnCoSo.Migrations
{
    /// <inheritdoc />
    public partial class FixKhuyenMai : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserPromotions_UserId",
                table: "UserPromotions");

            migrationBuilder.AddColumn<bool>(
                name: "IsPrivate",
                table: "Promotions",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_UserPromotions_UserId_PromotionId",
                table: "UserPromotions",
                columns: new[] { "UserId", "PromotionId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserPromotions_UserId_PromotionId",
                table: "UserPromotions");

            migrationBuilder.DropColumn(
                name: "IsPrivate",
                table: "Promotions");

            migrationBuilder.CreateIndex(
                name: "IX_UserPromotions_UserId",
                table: "UserPromotions",
                column: "UserId");
        }
    }
}
