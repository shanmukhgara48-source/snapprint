import SimpleMockList from "./SimpleMockList";

interface Review {
  id: string;
  customer: string;
  product: string;
  rating: string;
  comment: string;
}

const initial: Review[] = [
  { id: "1", customer: "+91 98765 43210", product: "4x6 Glossy Print", rating: "5", comment: "Great quality, fast delivery!" },
  { id: "2", customer: "+91 91234 56789", product: "Photo Book", rating: "4", comment: "Nice but binding could be sturdier" },
];

export default function Reviews() {
  return (
    <SimpleMockList<Review>
      title="Reviews"
      subtitle="No review/rating model or UI exists in the customer app yet"
      columns={[
        { key: "customer", label: "Customer" },
        { key: "product", label: "Product" },
        { key: "rating", label: "Rating" },
        { key: "comment", label: "Comment" },
      ]}
      initialRows={initial}
    />
  );
}
