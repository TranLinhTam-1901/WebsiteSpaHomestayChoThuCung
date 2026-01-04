using DoAnCoSo.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DoAnCoSo.Controllers.Api
{
    [ApiController]
    [Route("api/products")]
    [AllowAnonymous]
    public class ProductsApiController : ControllerBase
    {
        private readonly IProductApiService _productService;

        public ProductsApiController(IProductApiService productService)
        {
            _productService = productService;
        }


        [HttpGet]
        public async Task<IActionResult> GetProducts(int? categoryId)
        {

            var products = await _productService.GetProductsAsync (categoryId);

            return Ok(products);
        }


        [HttpGet("{id}")]
        public async Task<IActionResult> GetProductDetail(int id)
        {
            var product = await _productService.GetProductDetailAsync(id);
            if (product == null) return NotFound();
            return Ok(product);
        }
    }
}
