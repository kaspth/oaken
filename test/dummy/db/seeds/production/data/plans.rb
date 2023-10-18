raise "This seed file executed outside of production" unless Rails.env.production?
