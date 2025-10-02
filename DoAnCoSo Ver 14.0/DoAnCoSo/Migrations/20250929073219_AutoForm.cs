using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DoAnCoSo.Migrations
{
    /// <inheritdoc />
    public partial class AutoForm : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_PetServiceRecords_PetProfiles_PetProfileId",
                table: "PetServiceRecords");

            migrationBuilder.DropTable(
                name: "PetProfiles");

            migrationBuilder.DropIndex(
                name: "IX_PetServiceRecords_PetProfileId",
                table: "PetServiceRecords");

            migrationBuilder.DropColumn(
                name: "PetProfileId",
                table: "PetServiceRecords");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "PetProfileId",
                table: "PetServiceRecords",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "PetProfiles",
                columns: table => new
                {
                    PetProfileId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PetId = table.Column<int>(type: "int", nullable: false),
                    Age = table.Column<int>(type: "int", nullable: false),
                    Breed = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    MedicalHistory = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Weight = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PetProfiles", x => x.PetProfileId);
                    table.ForeignKey(
                        name: "FK_PetProfiles_Pets_PetId",
                        column: x => x.PetId,
                        principalTable: "Pets",
                        principalColumn: "PetId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PetServiceRecords_PetProfileId",
                table: "PetServiceRecords",
                column: "PetProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_PetProfiles_PetId",
                table: "PetProfiles",
                column: "PetId");

            migrationBuilder.AddForeignKey(
                name: "FK_PetServiceRecords_PetProfiles_PetProfileId",
                table: "PetServiceRecords",
                column: "PetProfileId",
                principalTable: "PetProfiles",
                principalColumn: "PetProfileId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
