using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DoAnCoSo.Migrations
{
    /// <inheritdoc />
    public partial class AddSpaPricingDbSet : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_SpaPricing_Services_ServiceId",
                table: "SpaPricing");

            migrationBuilder.DropPrimaryKey(
                name: "PK_SpaPricing",
                table: "SpaPricing");

            migrationBuilder.RenameTable(
                name: "SpaPricing",
                newName: "SpaPricings");

            migrationBuilder.RenameIndex(
                name: "IX_SpaPricing_ServiceId",
                table: "SpaPricings",
                newName: "IX_SpaPricings_ServiceId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_SpaPricings",
                table: "SpaPricings",
                column: "SpaPricingId");

            migrationBuilder.AddForeignKey(
                name: "FK_SpaPricings_Services_ServiceId",
                table: "SpaPricings",
                column: "ServiceId",
                principalTable: "Services",
                principalColumn: "ServiceId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_SpaPricings_Services_ServiceId",
                table: "SpaPricings");

            migrationBuilder.DropPrimaryKey(
                name: "PK_SpaPricings",
                table: "SpaPricings");

            migrationBuilder.RenameTable(
                name: "SpaPricings",
                newName: "SpaPricing");

            migrationBuilder.RenameIndex(
                name: "IX_SpaPricings_ServiceId",
                table: "SpaPricing",
                newName: "IX_SpaPricing_ServiceId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_SpaPricing",
                table: "SpaPricing",
                column: "SpaPricingId");

            migrationBuilder.AddForeignKey(
                name: "FK_SpaPricing_Services_ServiceId",
                table: "SpaPricing",
                column: "ServiceId",
                principalTable: "Services",
                principalColumn: "ServiceId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
