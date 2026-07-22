module DropSerializer
  module_function

  def product(product)
    {
      id: product.id,
      name: product.name,
      slug: product.slug,
      tagline: product.tagline,
      hero_image_path: product.hero_image_path,
      watching_count: product.watching_count + rand(0..12),
      claimed_count: product.claimed_count,
      stock_remaining: product.stock_remaining,
      next_milestone: product.next_milestone,
      variants: product.drop_variants.map { |variant| variant_hash(variant) }
    }
  end

  def variant_hash(variant)
    {
      id: variant.id,
      name: variant.name,
      sku: variant.sku,
      image_path: variant.image_path,
      stock: variant.stock,
      claimed_count: variant.claimed_count
    }
  end

  def event(event)
    {
      id: event.id,
      kind: event.kind,
      actor: event.actor,
      emoji: event.emoji,
      body: event.body,
      variant_id: event.drop_variant_id,
      variant_name: event.drop_variant&.name,
      created_at: event.created_at.iso8601
    }
  end
end
